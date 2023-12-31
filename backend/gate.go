package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"regexp"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
)

var staticChevrons [24]uint = [24]uint{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24}

func cleanUpRegionName(region string) string {
	pRegion := regexp.MustCompile(`(.+) \(\d+, \d+\)`)
	matches := pRegion.FindAllStringSubmatch(region, -1)

	if len(matches) == 1 && len(matches[0]) == 2 {
		return matches[0][1]
	}

	return "Unknown region"
}

func assignGateAddress(db *pgx.Conn, gateUUID string, tries uint) {
	if tries > 10 {
		log.Panic("ERROR - unable to assign a gate address after 10 attempts.")
	}

	var gateAddress [7]uint

	chevrons := make([]uint, 24)
	copy(chevrons, staticChevrons[:])

	for i := 0; i < 7; i++ {
		idx := rand.Intn(len(chevrons) - 1)
		chevron := chevrons[idx]
		chevrons = append(chevrons[:idx], chevrons[idx+1:]...)
		gateAddress[i] = chevron
	}

	_, err := db.Exec(
		context.Background(),
		"INSERT INTO gate_coordinates(gate_uuid, one, two, three, four, five, six, seven) VALUES($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT (gate_uuid) DO NOTHING",
		gateUUID, gateAddress[0], gateAddress[1], gateAddress[2], gateAddress[3], gateAddress[4], gateAddress[5], gateAddress[6],
	)

	if err != nil {
		log.Printf("ERROR - unable to assign gate address: %v", err)
		assignGateAddress(db, gateUUID, tries+1)
	}
}

func registerNewGate(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	headers := c.GetReqHeaders()

	gateURL := string(c.Body())
	gateUUID := headers["X-Secondlife-Object-Key"]
	gateName := headers["X-Secondlife-Object-Name"]
	gateOwnerName := headers["X-Secondlife-Owner-Name"]
	gateOwnerUUID := headers["X-Secondlife-Owner-Key"]
	gateRegion := cleanUpRegionName(headers["X-Secondlife-Region"])

	banned, err := checkIfUserIsBanned(db, gateOwnerUUID)
	if err != nil {
		log.Printf("ERROR - unable to check if users is banned during registration: '%v'", err)
		return fiber.ErrInternalServerError
	}

	if banned {
		return fiber.ErrUnauthorized
	}

	_, err = db.Exec(context.Background(), "INSERT INTO gates (uuid, gate_url, gate_name, owner_name, owner_uuid, region) VALUES($1, $2, $3, $4, $5, $6) ON CONFLICT (uuid) DO UPDATE SET gate_url = EXCLUDED.gate_url, owner_name = EXCLUDED.owner_name, owner_uuid = EXCLUDED.owner_uuid, region = EXCLUDED.region, last_seen = NOW()", gateUUID, gateURL, gateName, gateOwnerName, gateOwnerUUID, gateRegion)
	if err != nil {
		log.Printf("ERROR - unable to register gate: %v", err)
		return fiber.ErrInternalServerError
	}

	assignGateAddress(db, gateUUID, 0)

	return nil
}

func gateDialSuccessReply(region string, address string, chev1 uint, chev2 uint, chev3 uint, chev4 uint, chev5 uint, chev6 uint, chev7 uint) string {
	return fmt.Sprintf("%s|%s|%d|%d|%d|%d|%d|%d|%d", region, address, chev1, chev2, chev3, chev4, chev5, chev6, chev7)
}

func dialGate(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	query := fmt.Sprintf("%%%s%%", strings.ToLower(string(c.FormValue("q"))))

	headers := c.GetReqHeaders()

	dialingGateUUID := headers["X-Secondlife-Object-Key"]

	//Need to check here too, because the gate doesnt technically need to be registered to dial
	gateOwnerUUID := headers["X-Secondlife-Owner-Key"]
	banned, err := checkIfUserIsBanned(db, gateOwnerUUID)
	if err != nil {
		log.Printf("ERROR - unable to check if user is banned during dial: '%v'", err)
		return fiber.ErrInternalServerError
	}

	if banned {
		return fiber.ErrUnauthorized
	}

	var address string
	var region string
	var chev1 uint
	var chev2 uint
	var chev3 uint
	var chev4 uint
	var chev5 uint
	var chev6 uint
	var chev7 uint
	var row pgx.Row

	if query != "%random%" {
		row = db.QueryRow(context.Background(), "SELECT g.gate_url, g.region, c.one, c.two, c.three, c.four, c.five, c.six, c.seven FROM gates g LEFT JOIN gate_coordinates c ON c.gate_uuid = g.uuid WHERE uuid <> $1 AND (LOWER(region) LIKE $2 OR LOWER(gate_name) LIKE $2) AND (last_seen+'2 hours'::interval >= NOW() AT TIME ZONE('UTC')) ORDER BY last_seen DESC LIMIT 1", dialingGateUUID, query)
	} else {
		row = db.QueryRow(context.Background(), "SELECT g.gate_url, g.region, c.one, c.two, c.three, c.four, c.five, c.six, c.seven	FROM GATES g LEFT JOIN gate_coordinates c ON c.gate_uuid = g.uuid WHERE uuid <> $1 AND (last_seen+'2 hours'::interval >= NOW() AT TIME ZONE('UTC')) ORDER BY RANDOM() LIMIT 1", dialingGateUUID)
	}

	err = row.Scan(&address, &region, &chev1, &chev2, &chev3, &chev4, &chev5, &chev6, &chev7)
	if err != nil {
		log.Printf("WARNING - found no gate matching query: '%v'", err)
		return fiber.ErrNotFound
	}

	return c.SendString(gateDialSuccessReply(region, address, chev1, chev2, chev3, chev4, chev5, chev6, chev7))
}

func dialByAddress(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	headers := c.GetReqHeaders()

	dialingGateUUID := headers["X-Secondlife-Object-Key"]
	//Need to check here too, because the gate doesnt technically need to be registered to dial
	gateOwnerUUID := headers["X-Secondlife-Owner-Key"]
	banned, err := checkIfUserIsBanned(db, gateOwnerUUID)
	if err != nil {
		log.Printf("ERROR - unable to check if user is banned during symbol dial: '%v'", err)
		return fiber.ErrInternalServerError
	}

	if banned {
		return fiber.ErrUnauthorized
	}

	symbols := make([]uint, 7)
	err = json.Unmarshal(c.Body(), &symbols)
	if err != nil {
		return fiber.ErrBadRequest
	}

	var address string
	var region string
	err = db.QueryRow(context.Background(), "SELECT g.gate_url, g.region FROM gates g LEFT JOIN gate_coordinates c ON c.gate_uuid = g.uuid WHERE g.uuid <> $1 AND c.one = $2 AND c.two = $3 AND c.three = $4 AND c.four = $5 AND c.five = $6 AND c.six = $7 AND c.seven = $8", dialingGateUUID, symbols[0], symbols[1], symbols[2], symbols[3], symbols[4], symbols[5], symbols[6]).Scan(&address, &region)
	if err != nil {
		return fiber.ErrNotFound
	}

	return c.SendString(gateDialSuccessReply(region, address, symbols[0], symbols[1], symbols[2], symbols[3], symbols[4], symbols[5], symbols[6]))
}

func updateGateState(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	state, _ := strconv.Atoi(string(c.Body()))
	gateUUID := c.GetReqHeaders()["X-Secondlife-Object-Key"]

	_, err := db.Exec(context.Background(), "UPDATE gates SET last_state = $1 WHERE uuid = $2", state, gateUUID)
	if err != nil {
		log.Printf("ERROR - unable to set gate state: '%v'", err)
		return fiber.ErrInternalServerError
	}

	return nil
}

func updateGate(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	headers := c.GetReqHeaders()

	gateUUID := headers["X-Secondlife-Object-Key"]
	gateName := headers["X-Secondlife-Object-Name"]
	gateOwnerName := headers["X-Secondlife-Owner-Name"]
	gateOwnerUUID := headers["X-Secondlife-Owner-Key"]
	gateRegion := cleanUpRegionName(headers["X-Secondlife-Region"])

	_, err := db.Exec(context.Background(), "UPDATE gates SET owner_name = $1, owner_uuid = $2, region = $3, gate_name = $4, last_seen = NOW() WHERE uuid = $5", gateOwnerName, gateOwnerUUID, gateRegion, gateName, gateUUID)

	if err != nil {
		log.Printf("ERROR - unable to update gate last seen: '%v'", err)
	}

	return nil
}

func deleteStargate(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	gateUUID := c.GetReqHeaders()["X-Secondlife-Object-Key"]

	var gateURL string
	err := db.QueryRow(context.Background(), "SELECT gate_url FROM gates WHERE uuid = $1", gateUUID).Scan(&gateURL)
	if err != nil {
		log.Printf("ERROR - unable to find gate url: '%v'", err)
		return fiber.ErrNotFound
	}

	agent := fiber.Delete(gateURL)
	status, _, errs := agent.Bytes()

	if len(errs) > 0 {
		log.Printf("ERROR - unable to connec to stargate for deletion: %v", errs)
		return fiber.ErrInternalServerError
	} else if status != 200 {
		return fiber.ErrMethodNotAllowed
	}

	_, err = db.Exec(context.Background(), "DELETE FROM gates WHERE uuid = $1", gateUUID)
	if err != nil {
		log.Printf("ERROR - unable to delete stargate from database: '%v'", err)
	}

	return nil
}

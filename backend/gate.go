package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
)

var staticChevrons [24]uint = [24]uint{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24}

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
	gateRegion := headers["X-Secondlife-Region"]

	_, err := db.Exec(context.Background(), "INSERT INTO gates (uuid, gate_url, gate_name, owner_name, owner_uuid, region) VALUES($1, $2, $3, $4, $5, $6) ON CONFLICT (uuid) DO UPDATE SET gate_url = EXCLUDED.gate_url, owner_name = EXCLUDED.owner_name, owner_uuid = EXCLUDED.owner_uuid, region = EXCLUDED.region, last_seen = NOW()", gateUUID, gateURL, gateName, gateOwnerName, gateOwnerUUID, gateRegion)
	if err != nil {
		log.Printf("ERROR - unable to register gate: %v", err)
		return fiber.ErrInternalServerError
	}

	assignGateAddress(db, gateUUID, 0)

	return nil
}

func dialGate(c *fiber.Ctx) error {
	db := getDBConnection()
	defer db.Close(context.Background())

	query := fmt.Sprintf("%%%s%%", string(c.FormValue("q")))

	dialingGateUUID := c.GetReqHeaders()["X-Secondlife-Object-Key"]

	var address string
	var region string
	var chev1 uint
	var chev2 uint
	var chev3 uint
	var chev4 uint
	var chev5 uint
	var chev6 uint
	var chev7 uint
	err := db.QueryRow(context.Background(), "SELECT g.gate_url, g.region, c.one, c.two, c.three, c.four, c.five, c.six, c.seven FROM gates g LEFT JOIN gate_coordinates c ON c.gate_uuid = g.uuid WHERE uuid <> $1 AND (LOWER(region) LIKE $2 OR LOWER(gate_name) LIKE $2) AND last_seen+'2 hours'::interval+'60 seconds'::interval >= NOW() ORDER BY last_seen DESC LIMIT 1", dialingGateUUID, query).Scan(&address, &region, &chev1, &chev2, &chev3, &chev4, &chev5, &chev6, &chev7)
	if err != nil {
		log.Printf("WARNING - found no gate matching query: '%v'", err)
		return fiber.ErrNotFound
	}

	return c.SendString(fmt.Sprintf("%s|%s|%d|%d|%d|%d|%d|%d|%d", region, address, chev1, chev2, chev3, chev4, chev5, chev6, chev7))
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
	gateRegion := headers["X-Secondlife-Region"]

	_, err := db.Exec(context.Background(), "UPDATE gates SET owner_name = $1, owner_uuid = $2, region = $3, gate_name = $4, last_seen = NOW() WHERE uuid = $5", gateOwnerName, gateOwnerUUID, gateRegion, gateName, gateUUID)

	if err != nil {
		log.Printf("ERROR - unable to update gate last seen: '%v'", err)
	}

	return nil
}

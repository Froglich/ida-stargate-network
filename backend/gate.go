package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
)

var staticChevrons [21]uint = [21]uint{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21}

func assignGateAddress(db *pgx.Conn, gateUUID string, tries uint) {
	if tries > 10 {
		log.Panic("ERROR - unable to assign a gate address after 10 attempts.")
	}

	var gateAddress [7]uint

	chevrons := make([]uint, 21)
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
	gateOwnerName := headers["X-Secondlife-Owner-Name"]
	gateOwnerUUID := headers["X-Secondlife-Owner-Key"]
	gateRegion := headers["X-Secondlife-Region"]

	_, err := db.Exec(context.Background(), "INSERT INTO gates (uuid, gate_url, owner_name, owner_uuid, region) VALUES($1, $2, $3, $4, $5) ON CONFLICT (uuid) DO UPDATE SET gate_url = EXCLUDED.gate_url, owner_name = EXCLUDED.owner_name, owner_uuid = EXCLUDED.owner_uuid, region = EXCLUDED.region, last_seen = NOW()", gateUUID, gateURL, gateOwnerName, gateOwnerUUID, gateRegion)
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

	var address string
	var region string
	var chev1 uint
	var chev2 uint
	var chev3 uint
	var chev4 uint
	var chev5 uint
	var chev6 uint
	var chev7 uint
	err := db.QueryRow(context.Background(), "SELECT g.gate_url, g.region, c.one, c.two, c.three, c.four, c.five, c.six, c.seven FROM gates g LEFT JOIN gate_coordinates c ON c.gate_uuid = g.uuid WHERE LOWER(region) LIKE $1 ORDER BY last_seen DESC LIMIT 1", query).Scan(&address, &region, &chev1, &chev2, &chev3, &chev4, &chev5, &chev6, &chev7)
	if err != nil {
		log.Printf("WARNING - found no gate matching query: '%v'", err)
		return fiber.ErrNotFound
	}

	return c.SendString(fmt.Sprintf("%s|%s|%d|%d|%d|%d|%d|%d|%d", region, address, chev1, chev2, chev3, chev4, chev5, chev6, chev7))
}

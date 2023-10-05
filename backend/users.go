package main

import (
	"context"

	"github.com/jackc/pgx/v5"
)

func checkIfUserIsBanned(db *pgx.Conn, uuid string) (bool, error) {
	var count uint
	err := db.QueryRow(context.Background(), "SELECT COUNT(*) FROM banned_users WHERE user_uuid = $1", uuid).Scan(&count)
	if err != nil {
		return true, err
	}

	if count > 0 {
		return true, nil
	}

	return false, nil
}

package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"path"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/jackc/pgx/v5"
)

func getDBConnection() *pgx.Conn {
	db, err := pgx.Connect(context.Background(),
		fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			os.Getenv("DB_HOST"),
			os.Getenv("DB_PORT"),
			os.Getenv("DB_USER"),
			os.Getenv("DB_PASSWORD"),
			os.Getenv("DB_NAME"),
		),
	)
	if err != nil {
		log.Printf("unexpeced error while establishing database connection: '%v'", err)
		panic("unable to establish database connection")
	}

	return db
}

func main() {
	port := os.Getenv("LISTEN_PORT")
	client := os.Getenv("LISTEN_CLIENT")

	f, err := os.OpenFile(path.Join(os.Getenv("LOG_DIR"), "isn.log"), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0655)
	if err != nil {
		log.Panicln(err)
	}
	defer f.Close()
	mw := io.MultiWriter(os.Stdout, f)
	log.SetOutput(mw)

	app := fiber.New()

	app.Use(recover.New(recover.Config{
		Next:             nil,
		EnableStackTrace: false,
		StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
			log.Printf("recovered from: '%v'", e)
		},
	}))

	app.Put("/register", registerNewGate)
	app.Post("/register", registerNewGate) //For compatibility with the sub 0.6-gates
	app.Get("/dial", dialGate)
	app.Put("/dial-address", dialByAddress)
	app.Post("/update", updateGate)
	app.Put("/state", updateGateState)
	app.Delete("/delete", deleteStargate)

	log.Printf("Starting server listening on %s:%s.", client, port)
	log.Fatal(app.Listen(fmt.Sprintf("%s:%s", client, port)))
}

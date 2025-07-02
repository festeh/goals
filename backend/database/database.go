package database

import (
	"context"

	"github.com/jackc/pgx/v5"
)

func CreateTables(conn *pgx.Conn) error {
	_, err := conn.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS projects (
			id SERIAL PRIMARY KEY,
			name TEXT NOT NULL
		);
		CREATE TABLE IF NOT EXISTS tasks (
			id SERIAL PRIMARY KEY,
			description TEXT NOT NULL,
			project_id INTEGER REFERENCES projects(id),
			due_date TIMESTAMPTZ,
			labels TEXT[]
		);
	`)
	return err
}

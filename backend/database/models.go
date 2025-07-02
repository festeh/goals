package database

import "time"

type Task struct {
	ID          int
	Description string
	ProjectID   int
	DueDate     time.Time
	Labels      []string
}

type Project struct {
	ID   int
	Name string
}

package database

import (
	"time"
	"github.com/lib/pq"
)

type Task struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	Description string         `gorm:"not null" json:"description"`
	ProjectID   *uint          `gorm:"index" json:"project_id"`
	Project     *Project       `gorm:"foreignKey:ProjectID" json:"project"`
	DueDate     *time.Time     `json:"due_date"`
	DueDatetime *time.Time     `json:"due_datetime"`
	Labels      pq.StringArray `gorm:"type:text[]" json:"labels"`
	Order       int            `gorm:"default:0" json:"order"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	CompletedAt *time.Time     `json:"completed_at"`
}

type Project struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"not null" json:"name"`
	Color     string    `gorm:"default:'gray'" json:"color"`
	Order     int       `gorm:"default:0" json:"order"`
	Tasks     []Task    `gorm:"foreignKey:ProjectID" json:"tasks"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

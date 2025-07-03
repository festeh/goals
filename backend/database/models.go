package database

import (
	"time"
	"gorm.io/gorm"
	"github.com/lib/pq"
)

type Task struct {
	ID          uint           `gorm:"primaryKey"`
	Description string         `gorm:"not null"`
	ProjectID   *uint          `gorm:"index"`
	Project     *Project       `gorm:"foreignKey:ProjectID"`
	DueDate     *time.Time
	Labels      pq.StringArray `gorm:"type:text[]"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   gorm.DeletedAt `gorm:"index"`
}

type Project struct {
	ID        uint           `gorm:"primaryKey"`
	Name      string         `gorm:"not null"`
	Tasks     []Task         `gorm:"foreignKey:ProjectID"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

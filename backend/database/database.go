package database

import (
	"os"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"github.com/dima-b/go-task-backend/logger"
)

var DB *gorm.DB

func InitDB() error {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		logger.Error("DATABASE_URL environment variable is not set").Send()
		panic("DATABASE_URL environment variable is not set")
	}
	
	logger.Info("Connecting to database").Send()
	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		logger.Error("Failed to connect to database").Err(err).Send()
		return err
	}

	logger.Info("Database connected successfully").Send()

	// Auto-migrate the schema
	logger.Info("Running database migrations").Send()
	err = DB.AutoMigrate(&Project{}, &Task{})
	if err != nil {
		logger.Error("Failed to run database migrations").Err(err).Send()
		return err
	}

	logger.Info("Database migrations completed successfully").Send()
	return nil
}

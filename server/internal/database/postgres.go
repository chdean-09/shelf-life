package database

import (
	"log"

	"github.com/chdean-09/shelflife/server/config"
	"github.com/chdean-09/shelflife/server/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB holds the GORM database connection.
var DB *gorm.DB

// Connect initialises the PostgreSQL connection and runs auto-migrations.
func Connect(cfg *config.Config) *gorm.DB {
	var err error

	DB, err = gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Auto-migrate all models
	if err := DB.AutoMigrate(
		&models.User{},
		&models.PantryItem{},
		&models.Product{},
		&models.WasteLog{},
	); err != nil {
		log.Fatalf("Failed to auto-migrate: %v", err)
	}

	log.Println("✅ Database connected and migrated")
	return DB
}

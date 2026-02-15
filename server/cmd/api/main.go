package main

import (
	"log"

	"github.com/chdean-09/shelflife/server/config"
	"github.com/chdean-09/shelflife/server/internal/database"
	"github.com/chdean-09/shelflife/server/internal/handlers"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Load configuration
	cfg := config.Load()

	// Connect to database
	db := database.Connect(cfg)

	// Create a new Gin router
	router := gin.Default()

	// Set up routes with database and config
	handlers.SetupRoutes(router, db, cfg)

	// Start the server
	log.Printf("🚀 Server starting on port %s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

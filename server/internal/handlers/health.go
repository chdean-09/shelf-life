package handlers

import (
	"net/http"

	"github.com/chdean-09/shelflife/server/config"
	"github.com/chdean-09/shelflife/server/internal/middleware"
	"github.com/chdean-09/shelflife/server/internal/services"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// SetupRoutes registers all HTTP routes.
func SetupRoutes(router *gin.Engine, db *gorm.DB, cfg *config.Config) {
	// Global middleware
	router.Use(middleware.CORSMiddleware())

	// Health check (public)
	router.GET("/health", healthCheck)

	// --- Public auth routes ---
	authHandler := NewAuthHandler(db, cfg)
	auth := router.Group("/api/v1/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/google", authHandler.GoogleSignIn)
	}

	// --- Protected API routes ---
	api := router.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(cfg))
	{
		api.GET("/ping", ping)

		// Pantry Items
		itemHandler := NewItemHandler(db)
		api.GET("/items", itemHandler.GetAll)
		api.POST("/items", itemHandler.Create)
		api.PUT("/items/:id", itemHandler.Update)
		api.DELETE("/items/:id", itemHandler.Delete)

		// Products
		offService := services.NewOpenFoodFactsService(db)
		productHandler := NewProductHandler(offService)
		api.GET("/products/:barcode", productHandler.GetByBarcode)

		// Sync
		syncService := services.NewSyncService(db)
		syncHandler := NewSyncHandler(syncService)
		api.POST("/sync", syncHandler.Sync)
	}
}

// healthCheck returns server status.
func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"message": "ShelfLife API is running",
	})
}

// ping returns a simple pong response.
func ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}

package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// SetupRoutes registers all HTTP routes
func SetupRoutes(router *gin.Engine) {
	// Health check endpoint
	router.GET("/health", healthCheck)

	// API group (for future routes)
	api := router.Group("/api/v1")
	{
		api.GET("/ping", ping)
	}
}

// healthCheck returns server status
func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"message": "ShelfLife API is running",
	})
}

// ping returns a simple pong response
func ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}

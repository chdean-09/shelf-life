package handlers

import (
	"net/http"

	"github.com/chdean-09/shelflife/server/internal/models"
	"github.com/chdean-09/shelflife/server/internal/services"
	"github.com/gin-gonic/gin"
)

// SyncHandler handles batch sync of pantry items.
type SyncHandler struct {
	Service *services.SyncService
}

// NewSyncHandler creates a new SyncHandler.
func NewSyncHandler(service *services.SyncService) *SyncHandler {
	return &SyncHandler{Service: service}
}

type syncRequest struct {
	Items []models.PantryItem `json:"items" binding:"required"`
}

// Sync receives unsynced items from the mobile client and upserts them.
func (h *SyncHandler) Sync(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req syncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	synced, err := h.Service.SyncItems(userID, req.Items)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sync failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"synced": synced})
}

package handlers

import (
	"net/http"
	"strconv"

	"github.com/chdean-09/shelflife/server/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ItemHandler handles CRUD operations for pantry items.
type ItemHandler struct {
	DB *gorm.DB
}

// NewItemHandler creates a new ItemHandler.
func NewItemHandler(db *gorm.DB) *ItemHandler {
	return &ItemHandler{DB: db}
}

type createItemRequest struct {
	Name            string `json:"name" binding:"required"`
	ExpiryDate      string `json:"expiry_date" binding:"required"` // RFC3339
	StorageLocation string `json:"storage_location" binding:"required"`
	Category        string `json:"category"`
	Barcode         string `json:"barcode"`
}

type updateItemRequest struct {
	Name            string `json:"name"`
	ExpiryDate      string `json:"expiry_date"`
	StorageLocation string `json:"storage_location"`
	Category        string `json:"category"`
	Barcode         string `json:"barcode"`
}

// GetAll returns all pantry items for the authenticated user.
func (h *ItemHandler) GetAll(c *gin.Context) {
	userID := c.GetUint("user_id")

	var items []models.PantryItem
	if err := h.DB.Where("user_id = ?", userID).Order("expiry_date ASC").Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch items"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"items": items})
}

// Create adds a new pantry item.
func (h *ItemHandler) Create(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req createItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item := models.PantryItem{
		UserID:          userID,
		Name:            req.Name,
		StorageLocation: req.StorageLocation,
		Category:        req.Category,
		Barcode:         req.Barcode,
	}

	// Parse expiry date
	if err := item.ExpiryDate.UnmarshalText([]byte(req.ExpiryDate)); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid expiry_date format, use RFC3339"})
		return
	}

	if err := h.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create item"})
		return
	}

	c.JSON(http.StatusCreated, item)
}

// Update modifies an existing pantry item.
func (h *ItemHandler) Update(c *gin.Context) {
	userID := c.GetUint("user_id")
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	var item models.PantryItem
	if err := h.DB.Where("id = ? AND user_id = ?", id, userID).First(&item).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	var req updateItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]any{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.ExpiryDate != "" {
		var t models.PantryItem
		if err := t.ExpiryDate.UnmarshalText([]byte(req.ExpiryDate)); err == nil {
			updates["expiry_date"] = t.ExpiryDate
		}
	}
	if req.StorageLocation != "" {
		updates["storage_location"] = req.StorageLocation
	}
	if req.Category != "" {
		updates["category"] = req.Category
	}
	if req.Barcode != "" {
		updates["barcode"] = req.Barcode
	}

	if len(updates) > 0 {
		h.DB.Model(&item).Updates(updates)
	}

	// Reload
	h.DB.First(&item, item.ID)
	c.JSON(http.StatusOK, item)
}

// Delete removes a pantry item.
func (h *ItemHandler) Delete(c *gin.Context) {
	userID := c.GetUint("user_id")
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	result := h.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.PantryItem{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	c.Status(http.StatusNoContent)
}

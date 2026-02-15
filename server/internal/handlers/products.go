package handlers

import (
	"net/http"

	"github.com/chdean-09/shelflife/server/internal/services"
	"github.com/gin-gonic/gin"
)

// ProductHandler handles product lookup by barcode.
type ProductHandler struct {
	Service *services.OpenFoodFactsService
}

// NewProductHandler creates a new ProductHandler.
func NewProductHandler(service *services.OpenFoodFactsService) *ProductHandler {
	return &ProductHandler{Service: service}
}

// GetByBarcode looks up a product by barcode (cache → OpenFoodFacts).
func (h *ProductHandler) GetByBarcode(c *gin.Context) {
	barcode := c.Param("barcode")
	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Barcode is required"})
		return
	}

	product, err := h.Service.LookupBarcode(barcode)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, product)
}

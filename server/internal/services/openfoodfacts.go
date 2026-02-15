package services

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/chdean-09/shelflife/server/internal/models"
	"gorm.io/gorm"
)

// OpenFoodFactsService handles product lookups via the OpenFoodFacts API.
type OpenFoodFactsService struct {
	DB     *gorm.DB
	client *http.Client
}

// NewOpenFoodFactsService creates a new service instance.
func NewOpenFoodFactsService(db *gorm.DB) *OpenFoodFactsService {
	return &OpenFoodFactsService{
		DB: db,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// openFoodFactsResponse maps the relevant fields from the API response.
type openFoodFactsResponse struct {
	Status  int `json:"status"`
	Product struct {
		ProductName string `json:"product_name"`
		Brands      string `json:"brands"`
		ImageURL    string `json:"image_front_url"`
		Categories  string `json:"categories"`
	} `json:"product"`
}

// LookupBarcode checks the local DB cache first, then queries OpenFoodFacts.
func (s *OpenFoodFactsService) LookupBarcode(barcode string) (*models.Product, error) {
	// 1. Check local cache
	var cached models.Product
	if err := s.DB.Where("barcode = ?", barcode).First(&cached).Error; err == nil {
		return &cached, nil
	}

	// 2. Fetch from OpenFoodFacts
	url := fmt.Sprintf("https://world.openfoodfacts.org/api/v0/product/%s.json", barcode)
	resp, err := s.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to query OpenFoodFacts: %w", err)
	}
	defer resp.Body.Close()

	var result openFoodFactsResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode OpenFoodFacts response: %w", err)
	}

	if result.Status != 1 {
		return nil, fmt.Errorf("product not found in OpenFoodFacts")
	}

	product := models.Product{
		Barcode:  barcode,
		Name:     result.Product.ProductName,
		Brand:    result.Product.Brands,
		ImageURL: result.Product.ImageURL,
		Category: result.Product.Categories,
		CachedAt: time.Now(),
	}

	// 3. Cache in DB
	s.DB.Create(&product)

	return &product, nil
}

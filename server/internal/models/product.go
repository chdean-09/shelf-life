package models

import "time"

// Product caches product data from OpenFoodFacts lookups.
type Product struct {
	ID       uint      `gorm:"primaryKey" json:"id"`
	Barcode  string    `gorm:"uniqueIndex;size:50;not null" json:"barcode"`
	Name     string    `gorm:"size:255" json:"name"`
	Brand    string    `gorm:"size:255" json:"brand,omitempty"`
	ImageURL string    `gorm:"type:text" json:"image_url,omitempty"`
	Category string    `gorm:"size:100" json:"category,omitempty"`
	CachedAt time.Time `json:"cached_at"`
}

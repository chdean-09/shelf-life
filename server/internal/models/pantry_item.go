package models

import (
	"time"

	"gorm.io/gorm"
)

// PantryItem represents a food item in the user's pantry.
type PantryItem struct {
	ID              uint           `gorm:"primaryKey" json:"id"`
	UserID          uint           `gorm:"index;not null" json:"user_id"`
	Name            string         `gorm:"size:255;not null" json:"name"`
	ExpiryDate      time.Time      `gorm:"index;not null" json:"expiry_date"`
	StorageLocation string         `gorm:"size:50;not null" json:"storage_location"` // pantry, fridge, freezer
	Category        string         `gorm:"size:100" json:"category,omitempty"`
	Barcode         string         `gorm:"size:50" json:"barcode,omitempty"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// WasteLog records a discarded food item for waste tracking.
type WasteLog struct {
	ID             uint      `gorm:"primaryKey" json:"id"`
	UserID         uint      `gorm:"index;not null" json:"user_id"`
	ItemName       string    `gorm:"size:255;not null" json:"item_name"`
	Category       string    `gorm:"size:100" json:"category,omitempty"`
	EstimatedPrice float64   `gorm:"type:decimal(10,2);not null" json:"estimated_price"`
	WastedDate     time.Time `gorm:"index;not null" json:"wasted_date"`
	CreatedAt      time.Time `json:"created_at"`
}

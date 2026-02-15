package models

import (
	"time"

	"gorm.io/gorm"
)

// User represents a registered user.
type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Email     string         `gorm:"uniqueIndex;size:255;not null" json:"email"`
	Password  string         `gorm:"size:255" json:"-"` // NULL for Google OAuth users
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// Associations
	PantryItems []PantryItem `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
	WasteLogs   []WasteLog   `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
}

// UserResponse is the public-facing user representation (no password).
type UserResponse struct {
	ID        uint      `json:"id"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

// ToResponse converts a User to a safe response struct.
func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:        u.ID,
		Email:     u.Email,
		CreatedAt: u.CreatedAt,
	}
}

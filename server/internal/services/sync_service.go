package services

import (
	"github.com/chdean-09/shelflife/server/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// SyncService handles merging items from the mobile client.
type SyncService struct {
	DB *gorm.DB
}

// NewSyncService creates a new service instance.
func NewSyncService(db *gorm.DB) *SyncService {
	return &SyncService{DB: db}
}

// SyncItems upserts a batch of pantry items for the given user.
// Uses last-write-wins strategy based on UpdatedAt timestamps.
func (s *SyncService) SyncItems(userID uint, items []models.PantryItem) (int, error) {
	synced := 0

	for i := range items {
		items[i].UserID = userID

		result := s.DB.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{"name", "expiry_date", "storage_location", "category", "barcode", "updated_at"}),
			Where: clause.Where{
				Exprs: []clause.Expression{
					clause.Expr{SQL: "pantry_items.updated_at < excluded.updated_at"},
				},
			},
		}).Create(&items[i])

		if result.Error != nil {
			return synced, result.Error
		}
		if result.RowsAffected > 0 {
			synced++
		}
	}

	return synced, nil
}

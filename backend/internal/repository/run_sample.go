package repository

import (
	"context"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type RunSampleRepository struct {
	db *gorm.DB
}

func NewRunSampleRepository(db *gorm.DB) *RunSampleRepository {
	return &RunSampleRepository{db: db}
}

func (r *RunSampleRepository) BatchCreate(ctx context.Context, samples []model.RunSample) error {
	if len(samples) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).CreateInBatches(samples, 100).Error
}

func (r *RunSampleRepository) ListByRunID(ctx context.Context, runID string) ([]model.RunSample, error) {
	var samples []model.RunSample
	err := r.db.WithContext(ctx).
		Where("run_id = ?", runID).
		Order("sample_time ASC").
		Find(&samples).Error
	return samples, err
}

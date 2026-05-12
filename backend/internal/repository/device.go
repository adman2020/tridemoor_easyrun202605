package repository

import (
	"context"
	"time"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type DeviceRepository struct {
	db *gorm.DB
}

func NewDeviceRepository(db *gorm.DB) *DeviceRepository {
	return &DeviceRepository{db: db}
}

func (r *DeviceRepository) ListByUser(ctx context.Context, userID string) ([]model.Device, error) {
	var devices []model.Device
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("updated_at DESC").
		Find(&devices).Error
	return devices, err
}

func (r *DeviceRepository) FindByID(ctx context.Context, id string) (*model.Device, error) {
	var dev model.Device
	err := r.db.WithContext(ctx).First(&dev, "id = ?", id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &dev, nil
}

func (r *DeviceRepository) FindByUserAndMAC(ctx context.Context, userID, macAddr string) (*model.Device, error) {
	var dev model.Device
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND mac_addr = ?", userID, macAddr).
		First(&dev).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &dev, nil
}

func (r *DeviceRepository) Create(ctx context.Context, dev *model.Device) error {
	return r.db.WithContext(ctx).Create(dev).Error
}

func (r *DeviceRepository) Update(ctx context.Context, dev *model.Device) error {
	return r.db.WithContext(ctx).Save(dev).Error
}

func (r *DeviceRepository) Delete(ctx context.Context, id, userID string) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND user_id = ?", id, userID).
		Delete(&model.Device{}).Error
}

func (r *DeviceRepository) UpdateConnected(ctx context.Context, id string, connected bool) error {
	return r.db.WithContext(ctx).Model(&model.Device{}).
		Where("id = ?", id).
		Update("is_connected", connected).Error
}

func (r *DeviceRepository) UpdateBattery(ctx context.Context, id string, battery int8) error {
	return r.db.WithContext(ctx).Model(&model.Device{}).
		Where("id = ?", id).
		Update("battery", battery).Error
}

func (r *DeviceRepository) UpdateLastSync(ctx context.Context, id string, t time.Time) error {
	return r.db.WithContext(ctx).Model(&model.Device{}).
		Where("id = ?", id).
		Update("last_sync_at", t).Error
}

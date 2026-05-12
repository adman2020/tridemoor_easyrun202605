package model

import "time"

// DeviceType 设备类型
type DeviceType string

const (
	DeviceTypeSmartwatch     DeviceType = "smartwatch"
	DeviceTypeFitnessBand    DeviceType = "fitness_band"
	DeviceTypeHRMonitor      DeviceType = "hr_monitor"
	DeviceTypeSmartRing      DeviceType = "smart_ring"
	DeviceTypeOther          DeviceType = "other"
)

// ConnType 连接/数据源类型
type ConnType string

const (
	ConnTypeBLE          ConnType = "ble"
	ConnTypeAppleHealth  ConnType = "apple_health"
	ConnTypeHuaweiHealth ConnType = "huawei_health"
	ConnTypeGarmin       ConnType = "garmin"
	ConnTypeHealthConnect ConnType = "health_connect"
)

// Device 用户绑定的可穿戴设备
type Device struct {
	ID          string     `gorm:"type:char(36);primaryKey" json:"id"`
	UserID      string     `gorm:"type:char(36);not null;index:idx_device_user" json:"user_id"`
	Name        string     `gorm:"type:varchar(100);not null" json:"name"`
	DeviceType  DeviceType `gorm:"type:varchar(50);not null" json:"device_type"`
	Brand       string     `gorm:"type:varchar(50);not null" json:"brand"`
	Model       string     `gorm:"type:varchar(100);default:''" json:"model"`
	ConnType    ConnType   `gorm:"type:varchar(50);not null" json:"conn_type"`
	MACAddr     string     `gorm:"type:varchar(100);default:''" json:"mac_addr"`
	IsConnected bool       `gorm:"default:false" json:"is_connected"`
	Battery     *int8      `gorm:"type:tinyint" json:"battery,omitempty"`
	LastSyncAt  *time.Time `gorm:"type:datetime(3)" json:"last_sync_at,omitempty"`
	CreatedAt   time.Time  `gorm:"type:datetime(3);default:CURRENT_TIMESTAMP(3)" json:"created_at"`
	UpdatedAt   time.Time  `gorm:"type:datetime(3);default:CURRENT_TIMESTAMP(3)" json:"updated_at"`
}

func (Device) TableName() string {
	return "devices"
}

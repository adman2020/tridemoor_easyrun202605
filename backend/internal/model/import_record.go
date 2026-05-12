package model

import "time"

// ImportRecord 跑步记录导入历史（防重复导入）
type ImportRecord struct {
	ID         string    `gorm:"type:char(36);primaryKey" json:"id"`
	UserID     string    `gorm:"type:char(36);not null;index:idx_import_user" json:"user_id"`
	RunID      string    `gorm:"type:char(36);not null" json:"run_id"`
	Source     string    `gorm:"type:varchar(50);not null;index:idx_import_source" json:"source"`
	SourceID   string    `gorm:"type:varchar(255);not null;uniqueIndex:uk_source_srcid" json:"source_id"`
	DeviceID   *string   `gorm:"type:char(36)" json:"device_id,omitempty"`
	ImportedAt time.Time `gorm:"type:datetime(3);default:CURRENT_TIMESTAMP(3)" json:"imported_at"`
}

func (ImportRecord) TableName() string {
	return "import_records"
}

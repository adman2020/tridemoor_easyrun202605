package service

import (
	"context"
	"errors"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"

	"github.com/google/uuid"
)

type DeviceService struct {
	deviceRepo *repository.DeviceRepository
	runRepo    *repository.RunRepository
	sampleRepo *repository.RunSampleRepository
}

func NewDeviceService(deviceRepo *repository.DeviceRepository, runRepo *repository.RunRepository, sampleRepo *repository.RunSampleRepository) *DeviceService {
	return &DeviceService{deviceRepo: deviceRepo, runRepo: runRepo, sampleRepo: sampleRepo}
}

// ==================== 设备 CRUD ====================

type BindDeviceRequest struct {
	Name       string `json:"name" binding:"required"`
	DeviceType string `json:"device_type" binding:"required"`
	Brand      string `json:"brand" binding:"required"`
	Model      string `json:"model"`
	ConnType   string `json:"conn_type" binding:"required"`
	MACAddr    string `json:"mac_addr"`
}

type UpdateDeviceRequest struct {
	Name        *string `json:"name"`
	IsConnected *bool   `json:"is_connected"`
	Battery     *int8   `json:"battery"`
}

type DeviceResponse struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	DeviceType  string     `json:"device_type"`
	Brand       string     `json:"brand"`
	Model       string     `json:"model"`
	ConnType    string     `json:"conn_type"`
	MACAddr     string     `json:"mac_addr"`
	IsConnected bool       `json:"is_connected"`
	Battery     *int8      `json:"battery,omitempty"`
	LastSyncAt  *time.Time `json:"last_sync_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

func toDeviceResponse(d *model.Device) DeviceResponse {
	return DeviceResponse{
		ID:          d.ID,
		Name:        d.Name,
		DeviceType:  string(d.DeviceType),
		Brand:       d.Brand,
		Model:       d.Model,
		ConnType:    string(d.ConnType),
		MACAddr:     d.MACAddr,
		IsConnected: d.IsConnected,
		Battery:     d.Battery,
		LastSyncAt:  d.LastSyncAt,
		CreatedAt:   d.CreatedAt,
	}
}

func (s *DeviceService) ListDevices(ctx context.Context, userID string) ([]DeviceResponse, error) {
	devices, err := s.deviceRepo.ListByUser(ctx, userID)
	if err != nil {
		return nil, err
	}
	resp := make([]DeviceResponse, len(devices))
	for i, d := range devices {
		resp[i] = toDeviceResponse(&d)
	}
	return resp, nil
}

func (s *DeviceService) BindDevice(ctx context.Context, userID string, req *BindDeviceRequest) (*DeviceResponse, error) {
	// 如果传了 MAC 地址，检查是否已绑定
	if req.MACAddr != "" {
		existing, _ := s.deviceRepo.FindByUserAndMAC(ctx, userID, req.MACAddr)
		if existing != nil {
			return nil, errors.New("该设备已绑定")
		}
	}

	dev := &model.Device{
		ID:          uuid.New().String(),
		UserID:      userID,
		Name:        req.Name,
		DeviceType:  model.DeviceType(req.DeviceType),
		Brand:       req.Brand,
		Model:       req.Model,
		ConnType:    model.ConnType(req.ConnType),
		MACAddr:     req.MACAddr,
		IsConnected: true,
	}
	if err := s.deviceRepo.Create(ctx, dev); err != nil {
		return nil, err
	}
	resp := toDeviceResponse(dev)
	return &resp, nil
}

func (s *DeviceService) UpdateDevice(ctx context.Context, userID, deviceID string, req *UpdateDeviceRequest) (*DeviceResponse, error) {
	dev, err := s.deviceRepo.FindByID(ctx, deviceID)
	if err != nil {
		return nil, err
	}
	if dev == nil || dev.UserID != userID {
		return nil, errors.New("设备不存在")
	}
	if req.Name != nil {
		dev.Name = *req.Name
	}
	if req.IsConnected != nil {
		dev.IsConnected = *req.IsConnected
	}
	if req.Battery != nil {
		dev.Battery = req.Battery
	}
	if err := s.deviceRepo.Update(ctx, dev); err != nil {
		return nil, err
	}
	resp := toDeviceResponse(dev)
	return &resp, nil
}

func (s *DeviceService) UnbindDevice(ctx context.Context, userID, deviceID string) error {
	return s.deviceRepo.Delete(ctx, deviceID, userID)
}

// ==================== 数据导入 ====================

type ImportRunRequest struct {
	Source        string                 `json:"source" binding:"required"`         // 数据来源
	SourceID      string                 `json:"source_id" binding:"required"`      // 来源端唯一 ID
	DeviceID      *string                `json:"device_id"`                         // 关联设备
	StartTime     time.Time              `json:"start_time" binding:"required"`
	EndTime       time.Time              `json:"end_time" binding:"required"`
	TotalDistance float64                `json:"total_distance" binding:"required"`
	TotalTime     int64                  `json:"total_time" binding:"required"`
	AvgPace       *int                   `json:"avg_pace"`
	AvgHeartRate  *int                   `json:"avg_heart_rate"`
	MaxHeartRate  *int                   `json:"max_heart_rate"`
	AvgCadence    *int                   `json:"avg_cadence"`
	ElevationGain *float64               `json:"elevation_gain"`
	ElevationLoss *float64               `json:"elevation_loss"`
	Calories      *float64               `json:"calories"`
	Samples       []ImportSamplePoint    `json:"samples"` // GPS 采样（可选，某些平台提供）
}

type ImportSamplePoint struct {
	Latitude  float64  `json:"latitude"`
	Longitude float64  `json:"longitude"`
	Time      string   `json:"sample_time"`
	HeartRate *int     `json:"heart_rate,omitempty"`
	Cadence   *int     `json:"cadence,omitempty"`
}

type ImportRunResponse struct {
	RunID   string `json:"run_id"`
	Matched bool   `json:"matched"`
	RouteID string `json:"route_id,omitempty"`
}

func (s *DeviceService) ImportRun(ctx context.Context, userID string, req *ImportRunRequest) (*ImportRunResponse, error) {
	totalDistance := req.TotalDistance
	totalTime := req.TotalTime

	// 1. 检查是否已导入过
	existing, _ := s.runRepo.FindBySource(ctx, req.Source, req.SourceID)
	if existing != nil {
		return nil, errors.New("该记录已导入")
	}

	// 2. 类型转换
	var avgHR *int16
	if req.AvgHeartRate != nil {
		v := int16(*req.AvgHeartRate)
		avgHR = &v
	}
	var maxHR *int16
	if req.MaxHeartRate != nil {
		v := int16(*req.MaxHeartRate)
		maxHR = &v
	}
	var avgCad *int16
	if req.AvgCadence != nil {
		v := int16(*req.AvgCadence)
		avgCad = &v
	}
	elevationGain := float64(0)
	if req.ElevationGain != nil {
		elevationGain = *req.ElevationGain
	}
	elevationLoss := float64(0)
	if req.ElevationLoss != nil {
		elevationLoss = *req.ElevationLoss
	}
	var cal *int
	if req.Calories != nil {
		v := int(*req.Calories)
		cal = &v
	}

	avgPace := req.AvgPace
	if avgPace == nil && totalDistance > 0 && totalTime > 0 {
		pace := int(float64(totalTime) / (totalDistance / 1000.0))
		avgPace = &pace
	}

	totalTimeP := &totalTime
	totalDistP := &totalDistance

	// 3. 创建 Run
	runID := uuid.New().String()
	now := time.Now()
	sourceStr := req.Source

	run := &model.Run{
		ID:             runID,
		UserID:         userID,
		StartTime:      req.StartTime,
		EndTime:        &req.EndTime,
		TotalTime:      totalTimeP,
		TotalDistance:  totalDistP,
		AvgPace:        avgPace,
		AvgHeartRate:   avgHR,
		MaxHeartRate:   maxHR,
		AvgCadence:     avgCad,
		ElevationGain:  elevationGain,
		ElevationLoss:  elevationLoss,
		Calories:       cal,
		DeviceType:     &sourceStr,
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	if err := s.runRepo.Create(ctx, run); err != nil {
		return nil, err
	}

	// 4. 如果有 GPS 采样，创建 RunSamples
	if len(req.Samples) > 0 {
		samples := make([]model.RunSample, len(req.Samples))
		for i, sp := range req.Samples {
			sampleTime, parseErr := time.Parse(time.RFC3339Nano, sp.Time)
			if parseErr != nil {
				sampleTime, parseErr = time.Parse("2006-01-02T15:04:05", sp.Time)
				if parseErr != nil {
					sampleTime = time.Now()
				}
			}
			var hr *int16
			if sp.HeartRate != nil {
				hrVal := int16(*sp.HeartRate)
				hr = &hrVal
			}
			var cad *int16
			if sp.Cadence != nil {
				cadVal := int16(*sp.Cadence)
				cad = &cadVal
			}
			samples[i] = model.RunSample{
				RunID:      runID,
				SampleTime: sampleTime,
				Latitude:   sp.Latitude,
				Longitude:  sp.Longitude,
				HeartRate:  hr,
				Cadence:    cad,
			}
		}
		if err := s.sampleRepo.BatchCreate(ctx, samples); err != nil {
			return nil, err
		}
	}

	// 5. 创建导入记录
	importRec := &model.ImportRecord{
		ID:         uuid.New().String(),
		UserID:     userID,
		RunID:      runID,
		Source:     req.Source,
		SourceID:   req.SourceID,
		DeviceID:   req.DeviceID,
		ImportedAt: now,
	}
	if err := s.runRepo.CreateImportRecord(ctx, importRec); err != nil {
		return nil, err
	}

	// 6. 更新用户统计
	if totalDistance > 0 {
		_ = s.runRepo.UpdateUserStats(ctx, userID, totalDistance, totalTime, req.Calories)
	}

	resp := &ImportRunResponse{RunID: runID}
	return resp, nil
}

// ImportRecordResponse 导入记录响应
type ImportRecordResponse struct {
	ID         string    `json:"id"`
	Source     string    `json:"source"`
	SourceID   string    `json:"source_id"`
	RunID      string    `json:"run_id"`
	DeviceID   *string   `json:"device_id,omitempty"`
	ImportedAt time.Time `json:"imported_at"`
}

func (s *DeviceService) ListImportHistory(ctx context.Context, userID string) ([]ImportRecordResponse, error) {
	recs, err := s.runRepo.ListImportRecords(ctx, userID)
	if err != nil {
		return nil, err
	}
	resp := make([]ImportRecordResponse, len(recs))
	for i, r := range recs {
		resp[i] = ImportRecordResponse{
			ID:         r.ID,
			Source:     r.Source,
			SourceID:   r.SourceID,
			RunID:      r.RunID,
			DeviceID:   r.DeviceID,
			ImportedAt: r.ImportedAt,
		}
	}
	return resp, nil
}

func (s *DeviceService) DeleteImported(ctx context.Context, userID, importID string) error {
	return s.runRepo.DeleteImportRecord(ctx, importID, userID)
}

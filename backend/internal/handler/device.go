package handler

import (
	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type DeviceHandler struct {
	deviceSvc *service.DeviceService
}

func NewDeviceHandler(deviceSvc *service.DeviceService) *DeviceHandler {
	return &DeviceHandler{deviceSvc: deviceSvc}
}

// ==================== 设备管理 ====================

// ListDevices 获取用户设备列表
func (h *DeviceHandler) ListDevices(c *gin.Context) {
	userID, _ := c.Get("userID")
	devices, err := h.deviceSvc.ListDevices(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, 1, err.Error())
		return
	}
	response.Success(c, gin.H{"list": devices})
}

// BindDevice 绑定新设备
func (h *DeviceHandler) BindDevice(c *gin.Context) {
	userID, _ := c.Get("userID")
	var req service.BindDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	dev, err := h.deviceSvc.BindDevice(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Success(c, dev)
}

// UpdateDevice 更新设备信息
func (h *DeviceHandler) UpdateDevice(c *gin.Context) {
	userID, _ := c.Get("userID")
	deviceID := c.Param("id")
	var req service.UpdateDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	dev, err := h.deviceSvc.UpdateDevice(c.Request.Context(), userID.(string), deviceID, &req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Success(c, dev)
}

// UnbindDevice 解绑设备
func (h *DeviceHandler) UnbindDevice(c *gin.Context) {
	userID, _ := c.Get("userID")
	deviceID := c.Param("id")
	if err := h.deviceSvc.UnbindDevice(c.Request.Context(), userID.(string), deviceID); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Success(c, nil)
}

// ==================== 数据导入 ====================

// ImportRun 导入第三方跑步记录
func (h *DeviceHandler) ImportRun(c *gin.Context) {
	userID, _ := c.Get("userID")
	var req service.ImportRunRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "参数错误: "+err.Error())
		return
	}
	resp, err := h.deviceSvc.ImportRun(c.Request.Context(), userID.(string), &req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Success(c, resp)
}

// ListImportHistory 查看导入记录
func (h *DeviceHandler) ListImportHistory(c *gin.Context) {
	userID, _ := c.Get("userID")
	recs, err := h.deviceSvc.ListImportHistory(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, 1, err.Error())
		return
	}
	response.Success(c, gin.H{"list": recs})
}

// DeleteImported 删除导入记录（含关联跑步记录）
func (h *DeviceHandler) DeleteImported(c *gin.Context) {
	userID, _ := c.Get("userID")
	importID := c.Param("id")
	if err := h.deviceSvc.DeleteImported(c.Request.Context(), userID.(string), importID); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Success(c, nil)
}

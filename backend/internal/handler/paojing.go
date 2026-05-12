package handler

import (
	"stridemoor-api/internal/service"
	"stridemoor-api/pkg/response"

	"github.com/gin-gonic/gin"
)

type PaojingHandler struct {
	paojingService *service.PaojingService
}

func NewPaojingHandler(paojingService *service.PaojingService) *PaojingHandler {
	return &PaojingHandler{paojingService: paojingService}
}

// ==================== 调试接口 ====================

// DebugSetRealm POST /api/v1/admin/realm/debug-set 管理员设境界
// 仅开发/测试环境可用，方便验证晋升逻辑
func (h *PaojingHandler) DebugSetRealm(c *gin.Context) {
	type reqBody struct {
		Realm            int8     `json:"realm"`
		CompanionRuns    *int64   `json:"companion_runs,omitempty"`
		ChallengesWon    *int64   `json:"challenges_won,omitempty"`
		PostCount        *int64   `json:"post_count,omitempty"`
		BestMarathonTime *int64   `json:"best_marathon_time,omitempty"`
		BadgesJSON       *string  `json:"badges_json,omitempty"`
		TotalDistance    *float64 `json:"total_distance,omitempty"`
	}

	var req reqBody
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, response.CodeError, "参数错误: "+err.Error())
		return
	}

	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	if req.Realm < 0 || req.Realm > 12 {
		response.Error(c, response.CodeError, "境界范围 0-12")
		return
	}

	result, err := h.paojingService.DebugSetRealm(c.Request.Context(), userID.(string), req.Realm)
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	// 如果有额外字段，一并更新
	if req.CompanionRuns != nil || req.ChallengesWon != nil || req.PostCount != nil ||
		req.BestMarathonTime != nil || req.BadgesJSON != nil || req.TotalDistance != nil {
		updates := map[string]interface{}{}
		if req.CompanionRuns != nil {
			updates["companion_runs"] = *req.CompanionRuns
		}
		if req.ChallengesWon != nil {
			updates["challenges_won"] = *req.ChallengesWon
		}
		if req.PostCount != nil {
			updates["post_count"] = *req.PostCount
		}
		if req.BestMarathonTime != nil {
			updates["best_marathon_time"] = *req.BestMarathonTime
		}
		if req.BadgesJSON != nil {
			updates["realm_badges"] = *req.BadgesJSON
		}
		h.paojingService.DebugSetExtraFields(c.Request.Context(), userID.(string), updates)
	}

	// 返回最新跑境数据
	paojing, _ := h.paojingService.GetPaojing(c.Request.Context(), userID.(string))
	response.Success(c, gin.H{
		"upgrade_result": result,
		"paojing":        paojing,
	})
}

// GetPaojing GET /api/v1/user/paojing 获取跑境数据
func (h *PaojingHandler) GetPaojing(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	paojing, err := h.paojingService.GetPaojing(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, paojing)
}

// CheckUpgrade POST /api/v1/user/paojing/check 检查境界晋升
// 在用户发动态或跑完步后调用，判断是否满足晋升条件
func (h *PaojingHandler) CheckUpgrade(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "未登录")
		return
	}

	result, err := h.paojingService.CheckRealmUpgrade(c.Request.Context(), userID.(string))
	if err != nil {
		response.Error(c, response.CodeError, err.Error())
		return
	}

	response.Success(c, result)
}

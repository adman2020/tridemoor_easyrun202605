package service

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"
)

// AIService AI能力统一服务层
// 所有AI功能调用走这里，自动处理：配置读取→功能检查→调用→日志→降级
type AIService struct {
	keyRepo     *repository.AIKeyRepository
	logRepo     *repository.AICallLogRepository
	featureRepo *repository.FeatureConfigRepository
	clients     map[string]*http.Client // 按provider缓存
}

// NewAIService 创建AI服务
func NewAIService(keyRepo *repository.AIKeyRepository, logRepo *repository.AICallLogRepository, featureRepo *repository.FeatureConfigRepository) *AIService {
	return &AIService{
		keyRepo:     keyRepo,
		logRepo:     logRepo,
		featureRepo: featureRepo,
		clients: map[string]*http.Client{
			"deepseek": newHTTPClient(),
			"openai":   newHTTPClient(),
			"kimi":     newHTTPClient(),
			"qianwen":  newHTTPClient(),
		},
	}
}
func newHTTPClient() *http.Client {
	return &http.Client{
		Timeout: 30 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        10,
			IdleConnTimeout:     90 * time.Second,
			TLSHandshakeTimeout: 10 * time.Second,
		},
	}
}

// CallResult AI调用结果
type CallResult struct {
	Content  string
	Model    string
	Tokens   int
	Latency  int // ms
	Fallback bool
}

// Call 调用指定功能的AI模型，返回AI生成的文本
// usageScope: 对应 ai_feature_configs.feature_key
func (s *AIService) Call(ctx context.Context, usageScope string, systemPrompt string, userPrompt string) (*CallResult, error) {
	// 1. 检查功能配置（ai_feature_configs）
	featureCfg, cfgErr := s.featureRepo.GetByFeatureKey(usageScope)
	if cfgErr == nil {
		// 功能禁用检查
		if !featureCfg.Enabled {
			return nil, fmt.Errorf("功能已关闭: feature=%s", usageScope)
		}
		// 日限额检查
		if featureCfg.DailyLimit > 0 && featureCfg.TodayCalls >= featureCfg.DailyLimit {
			return nil, fmt.Errorf("功能已达日限额: feature=%s, limit=%d", usageScope, featureCfg.DailyLimit)
		}
	}

	// 2. 读取密钥配置
	//    - 如果 feature 配置关联了 api_key_id，用该特定密钥
	//    - 否则回退到按 usage_scope 查找（旧逻辑，兼容亚麻籽的客户API）
	var config *model.AIAPIKey
	var usingFallback bool

	usingFallback = true
	if cfgErr == nil && featureCfg.APIKeyID != nil && *featureCfg.APIKeyID > 0 {
		var keyErr error
		config, keyErr = s.keyRepo.GetByID(*featureCfg.APIKeyID)
		if keyErr == nil {
			// 覆盖模型
			if featureCfg.ModelOverride != "" {
				config.Model = featureCfg.ModelOverride
			}
			usingFallback = false
		}
	}

	if usingFallback {
		var err error
		config, err = s.keyRepo.GetEnabledConfig(usageScope)
		if err != nil {
			return nil, fmt.Errorf("AI配置未找到或未启用: scope=%s", usageScope)
		}
	}

	// 2. 构建请求
	body := s.buildRequest(config, systemPrompt, userPrompt)
	bodyBytes, _ := json.Marshal(body)

	// 3. 发送请求
	reqCtx, cancel := context.WithTimeout(ctx, 25*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(reqCtx, "POST", s.endpoint(config), bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, err
	}
	s.setHeaders(req, config, len(bodyBytes))

	// 4. 计时调用
	start := time.Now()
	resp, err := s.client(config.Provider).Do(req)
	latency := int(time.Since(start).Milliseconds())
	if err != nil {
		s.logCall(config, usageScope, "error", err.Error(), string(bodyBytes), "", latency)
		return nil, fmt.Errorf("AI请求失败: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	respStr := string(respBody)

	// 5. 解析响应
	if resp.StatusCode != http.StatusOK {
		s.logCall(config, usageScope, "error", fmt.Sprintf("HTTP %d: %s", resp.StatusCode, respStr), string(bodyBytes), respStr, latency)
		return nil, fmt.Errorf("AI返回错误: HTTP %d", resp.StatusCode)
	}

	var parsed struct {
		Choices []struct {
			Message struct{ Content string `json:"content"` }
		}
		Usage struct {
			PromptTokens     int `json:"prompt_tokens"`
			CompletionTokens int `json:"completion_tokens"`
			TotalTokens      int `json:"total_tokens"`
		}
		Usage_ struct {
			PromptTokens     int `json:"prompt_tokens"`
			CompletionTokens int `json:"completion_tokens"`
			TotalTokens      int `json:"total_tokens"`
		} `json:"usage"`
	}

	if err := json.Unmarshal(respBody, &parsed); err != nil {
		var alt struct {
			Content string `json:"content"`
		}
		if json.Unmarshal(respBody, &alt) == nil && alt.Content != "" {
			s.logCall(config, usageScope, "success", "", string(bodyBytes), respStr, latency)
			go s.featureRepo.IncrementTodayCalls(usageScope)
			return &CallResult{Content: alt.Content, Model: config.Model, Latency: latency}, nil
		}
		s.logCall(config, usageScope, "error", "响应解析失败: "+err.Error(), string(bodyBytes), respStr, latency)
		return nil, fmt.Errorf("AI响应解析失败: %w", err)
	}

	if len(parsed.Choices) == 0 {
		return nil, errors.New("AI返回空内容")
	}

	content := parsed.Choices[0].Message.Content
	usage := parsed.Usage
	if usage.TotalTokens == 0 {
		usage = parsed.Usage_
	}
	tokens := usage.TotalTokens

	s.logCall(config, usageScope, "success", "", string(bodyBytes), content, latency)
	// 6. 调用成功，递增功能配置的今日调用量
	go s.featureRepo.IncrementTodayCalls(usageScope)
	return &CallResult{Content: content, Model: config.Model, Tokens: tokens, Latency: latency}, nil
}

// logCall 写入调用日志（异步）
func (s *AIService) logCall(config *model.AIAPIKey, usageScope, status, errMsg, req, resp string, latencyMs int) {
	log := &model.AICallLog{
		APIKeyID:       &config.ID,
		Provider:       config.Provider,
		Model:          config.Model,
		UsageScope:     usageScope,
		RequestTokens:  0, // 从响应填充，这里先填0
		ResponseTokens: 0,
		DurationMs:     latencyMs,
		Status:         status,
		ErrorMsg:       errMsg,
	}
	go func() {
		s.logRepo.Create(log)
	}()
}

// buildRequest 根据provider构建请求体
func (s *AIService) buildRequest(config *model.AIAPIKey, system, user string) map[string]interface{} {
	base := map[string]interface{}{
		"model": config.Model,
		"messages": []map[string]string{
			{"role": "system", "content": system},
			{"role": "user", "content": user},
		},
		"max_tokens":   2048,
		"temperature":  0.7,
	}
	return base
}

func (s *AIService) endpoint(config *model.AIAPIKey) string {
	if config.BaseURL != "" {
		return config.BaseURL + "/chat/completions"
	}
	switch config.Provider {
	case "deepseek":
		return "https://api.deepseek.com/chat/completions"
	case "openai":
		return "https://api.openai.com/v1/chat/completions"
	case "kimi":
		return "https://api.moonshot.cn/v1/chat/completions"
	case "qianwen":
		return "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
	default:
		return "https://api.deepseek.com/chat/completions"
	}
}

func (s *AIService) setHeaders(req *http.Request, config *model.AIAPIKey, bodyLen int) {
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+config.APIKey)
	req.Header.Set("Content-Length", strconv.Itoa(bodyLen))
}

func (s *AIService) client(provider string) *http.Client {
	if c, ok := s.clients[provider]; ok {
		return c
	}
	return newHTTPClient()
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max] + "..."
}



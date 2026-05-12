package service

import (
	"context"
	"errors"

	"time"

	"stridemoor-api/internal/model"
	"stridemoor-api/internal/repository"
	"stridemoor-api/pkg/jwt"
	"stridemoor-api/pkg/password"

	"github.com/google/uuid"
)

type UserService struct {
	userRepo      *repository.UserRepository
	followRepo    *repository.FollowRepository
	bmRepo        *repository.RunBookmarkRepository
	challengeRepo *repository.ChallengeRepository
	jwtGen        *jwt.Generator
}

func NewUserService(
	userRepo *repository.UserRepository,
	followRepo *repository.FollowRepository,
	bmRepo *repository.RunBookmarkRepository,
	challengeRepo *repository.ChallengeRepository,
	jwtGen *jwt.Generator,
) *UserService {
	return &UserService{
		userRepo:      userRepo,
		followRepo:    followRepo,
		bmRepo:        bmRepo,
		challengeRepo: challengeRepo,
		jwtGen:        jwtGen,
	}
}

type RegisterRequest struct {
	Phone    string  `json:"phone" binding:"required,len=11"`
	Password string  `json:"password" binding:"required,min=6,max=20"`
	Email    string  `json:"email" binding:"required,email"`
	Weight   float64 `json:"weight" binding:"required,min=20,max=300"`
	Nickname string  `json:"nickname"`
}

type LoginRequest struct {
	Phone    string `json:"phone" binding:"required,len=11"`
	Password string `json:"password" binding:"required"`
}

type UserInfo struct {
	ID        string     `json:"id"`
	Phone     string     `json:"phone"`
	Nickname  string     `json:"nickname"`
	Avatar    string     `json:"avatar"`
	Email     string     `json:"email"`
	Bio       string     `json:"bio"`
	Gender    int8       `json:"gender"`
	Birthday  *time.Time `json:"birthday,omitempty"`
	Height    int16      `json:"height"`
	Weight    float64    `json:"weight"`
	IsVip     int8       `json:"is_vip"`
	VipTier   int8       `json:"vip_tier"`
	TotalDistance  float64 `json:"total_distance"`
	TotalRuns      int64   `json:"total_runs"`
	TotalTime      int64   `json:"total_time"`
	TotalCalories  int64   `json:"total_calories"`
	Realm          int8    `json:"realm"`
	RealmBadges    string  `json:"realm_badges"`
	CompanionRuns  int64   `json:"companion_runs"`
	ChallengesWon  int64   `json:"challenges_won"`
	BestMarathonTime int64 `json:"best_marathon_time"`
	PostCount       int64  `json:"post_count"`

	// 骑行预留
	CyclingRealm int8 `json:"cycling_realm"`

	CreatedAt time.Time  `json:"created_at"`
}

type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

func (s *UserService) Register(ctx context.Context, req *RegisterRequest) (*TokenPair, error) {
	existing, err := s.userRepo.FindByPhone(ctx, req.Phone)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("phone already registered")
	}

	hash, err := password.Hash(req.Password)
	if err != nil {
		return nil, err
	}

	nickname := req.Nickname
	if nickname == "" {
		nickname = "跑者"
	}

	user := &model.User{
		ID:           uuid.New().String(),
		Phone:        req.Phone,
		PasswordHash: hash,
		Nickname:     nickname,
		Settings:     "{}",
		RealmBadges:  "[]",
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return s.generateTokens(user.ID, user.Phone)
}

func (s *UserService) Login(ctx context.Context, req *LoginRequest) (*TokenPair, *UserInfo, error) {
	user, err := s.userRepo.FindByPhone(ctx, req.Phone)
	if err != nil {
		return nil, nil, err
	}
	if user == nil {
		return nil, nil, errors.New("user not found")
	}

	if !password.Verify(req.Password, user.PasswordHash) {
		return nil, nil, errors.New("invalid password")
	}

	tokens, err := s.generateTokens(user.ID, user.Phone)
	if err != nil {
		return nil, nil, err
	}

	info := s.toUserInfo(user)
	return tokens, info, nil
}

// UpdateProfileRequest 更新资料请求
type UpdateProfileRequest struct {
	Nickname *string  `json:"nickname"`
	Bio      *string  `json:"bio"`
	Gender   *int8    `json:"gender"`
	Birthday *string  `json:"birthday"`
	Height   *int16   `json:"height"`
	Weight   *float64 `json:"weight"`
	Email    *string  `json:"email"`
}

func (s *UserService) UpdateProfile(ctx context.Context, userID string, req *UpdateProfileRequest) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return err
	}
	if user == nil {
		return errors.New("user not found")
	}

	if req.Nickname != nil {
		user.Nickname = *req.Nickname
	}
	if req.Bio != nil {
		user.Bio = req.Bio
	}
	if req.Gender != nil {
		user.Gender = req.Gender
	}
	if req.Birthday != nil {
		user.Birthday = req.Birthday
	}
	if req.Height != nil {
		user.Height = req.Height
	}
	if req.Weight != nil {
		user.Weight = req.Weight
	}
	if req.Email != nil {
		user.Email = req.Email
	}

	return s.userRepo.Update(ctx, user)
}

func (s *UserService) GetUserInfo(ctx context.Context, userID string) (*UserInfo, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}
	return s.toUserInfo(user), nil
}

type UpdatePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

func (s *UserService) UpdatePassword(ctx context.Context, userID string, req *UpdatePasswordRequest) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return err
	}
	if user == nil {
		return errors.New("user not found")
	}

	if !password.Verify(req.OldPassword, user.PasswordHash) {
		return errors.New("invalid password")
	}

	newHash, err := password.Hash(req.NewPassword)
	if err != nil {
		return err
	}

	user.PasswordHash = newHash
	return s.userRepo.Update(ctx, user)
}

func (s *UserService) generateTokens(userID, phone string) (*TokenPair, error) {
	accessToken, err := s.jwtGen.GenerateAccessToken(userID, phone)
	if err != nil {
		return nil, err
	}
	refreshToken, err := s.jwtGen.GenerateRefreshToken(userID)
	if err != nil {
		return nil, err
	}
	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(s.jwtGen.AccessTTL().Seconds()),
	}, nil
}

// GetUserStats 获取指定用户跑步统计数据（供跑友详情页使用）
func (s *UserService) GetUserStats(ctx context.Context, userID string) (*UserInfo, error) {
	return s.GetUserInfo(ctx, userID)
}

// HeatStats 用户热度统计数据
type HeatStats struct {
	BookmarkCount           int64 `json:"bookmark_count"`
	CompanionCount          int64 `json:"companion_count"`
	FollowerCount           int64 `json:"follower_count"`
	// 被挑战（别人挑战我）
	ChallengeCount          int64 `json:"challenge_count"`
	ChallengeWins           int64 `json:"challenge_wins"`
	ChallengeLosses         int64 `json:"challenge_losses"`
	// 我的挑战（我挑战别人）
	MyChallengeCount        int64 `json:"my_challenge_count"`
	MyChallengeWins         int64 `json:"my_challenge_wins"`
	MyChallengeLosses       int64 `json:"my_challenge_losses"`
}

// GetHeatStats 获取当前用户的热度统计数据
func (s *UserService) GetHeatStats(ctx context.Context, userID string) (*HeatStats, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	bookmarkCount, err := s.bmRepo.CountByRunOwner(ctx, userID)
	if err != nil {
		bookmarkCount = 0
	}

	followerCount, err := s.followRepo.CountFollowers(ctx, userID)
	if err != nil {
		followerCount = 0
	}

	challengeCount, err := s.challengeRepo.CountChallengeReceived(ctx, userID)
	if err != nil {
		challengeCount = 0
	}

	// 被挑战胜负结果（不含进行中）
	wins, losses, _, _, err := s.challengeRepo.CountChallengeOutcomes(ctx, userID)
	if err != nil {
		wins, losses = 0, 0
	}

	// 我的挑战（我发起的）
	myCount, err := s.challengeRepo.CountChallengeInitiated(ctx, userID)
	if err != nil {
		myCount = 0
	}
	myWins, myLosses, err := s.challengeRepo.CountChallengeInitiatedOutcomes(ctx, userID)
	if err != nil {
		myWins, myLosses = 0, 0
	}

	return &HeatStats{
		BookmarkCount:      bookmarkCount,
		CompanionCount:     user.CompanionRuns,
		FollowerCount:      followerCount,
		ChallengeCount:     challengeCount,
		ChallengeWins:      wins,
		ChallengeLosses:    losses,
		MyChallengeCount:   myCount,
		MyChallengeWins:    myWins,
		MyChallengeLosses:  myLosses,
	}, nil
}

// RefreshToken 使用 Refresh Token 换取新的 Token 对
func (s *UserService) RefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	// 解析 Refresh Token 获取 userID
	claims, err := s.jwtGen.ParseToken(refreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	userID := claims.UserID
	if userID == "" {
		return nil, errors.New("invalid refresh token")
	}

	// 验证用户是否仍然存在
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	return s.generateTokens(user.ID, user.Phone)
}

func (s *UserService) toUserInfo(user *model.User) *UserInfo {
	info := &UserInfo{
		ID:        user.ID,
		Phone:     user.Phone,
		Nickname:  user.Nickname,
		CreatedAt: user.CreatedAt,
	}
	info.TotalDistance = user.TotalDistance
	info.TotalRuns = user.TotalRuns
	info.TotalTime = user.TotalTime
	info.TotalCalories = user.TotalCalories
	info.Realm = user.Realm
	info.RealmBadges = user.RealmBadges
	info.CompanionRuns = user.CompanionRuns
	info.ChallengesWon = user.ChallengesWon
	info.BestMarathonTime = user.BestMarathonTime
	info.PostCount = user.PostCount
	info.IsVip = user.IsVip
	info.VipTier = user.VipTier
	info.CyclingRealm = user.CyclingRealm
	if user.Avatar != nil {
		info.Avatar = *user.Avatar
	}
	if user.Email != nil {
		info.Email = *user.Email
	}
	if user.Bio != nil {
		info.Bio = *user.Bio
	}
	if user.Gender != nil {
		info.Gender = *user.Gender
	}
	if user.Birthday != nil {
		if t, err := time.Parse("2006-01-02", *user.Birthday); err == nil {
			info.Birthday = &t
		}
	}
	if user.Height != nil {
		info.Height = *user.Height
	}
	if user.Weight != nil {
		info.Weight = float64(*user.Weight)
	}
	return info
}

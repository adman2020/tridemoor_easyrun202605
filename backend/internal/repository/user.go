package repository

import (
	"context"
	"errors"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *model.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *UserRepository) FindByPhone(ctx context.Context, phone string) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Update(ctx context.Context, user *model.User) error {
	// GORM map updates 无法正确处理 *string/*int8 等指针类型，
	// 需手动解引用为实际值，nil 指针对应数据库 NULL
	ptrStr := func(s *string) interface{} {
		if s == nil { return nil }
		return *s
	}
	ptrInt8 := func(i *int8) interface{} {
		if i == nil { return nil }
		return *i
	}
	ptrInt16 := func(i *int16) interface{} {
		if i == nil { return nil }
		return *i
	}
	ptrFloat64 := func(f *float64) interface{} {
		if f == nil { return nil }
		return *f
	}

	return r.db.WithContext(ctx).Model(user).Updates(map[string]interface{}{
		"nickname":     user.Nickname,
		"avatar":       ptrStr(user.Avatar),
		"bio":          ptrStr(user.Bio),
		"email":        ptrStr(user.Email),
		"gender":       ptrInt8(user.Gender),
		"birthday":     ptrStr(user.Birthday),
		"height":       ptrInt16(user.Height),
		"weight":       ptrFloat64(user.Weight),
		"password_hash": user.PasswordHash,
	}).Error
}

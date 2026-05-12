package repository

import (
	"context"
	"errors"

	"stridemoor-api/internal/model"

	"gorm.io/gorm"
)

type PostRepository struct {
	db *gorm.DB
}

func NewPostRepository(db *gorm.DB) *PostRepository {
	return &PostRepository{db: db}
}

// ==================== Post ====================

func (r *PostRepository) Create(ctx context.Context, post *model.Post) error {
	return r.db.WithContext(ctx).Create(post).Error
}

func (r *PostRepository) FindByID(ctx context.Context, id string) (*model.Post, error) {
	var post model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Run").
		Preload("Route", func(db *gorm.DB) *gorm.DB {
			return db.Preload("Points", func(db2 *gorm.DB) *gorm.DB {
				return db2.Order("point_index ASC")
			})
		}).
		First(&post, "id = ?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	// 填充点赞数和评论数
	r.db.WithContext(ctx).Model(&model.PostLike{}).Where("post_id = ?", id).Count(&post.LikeCount)
	r.db.WithContext(ctx).Model(&model.PostComment{}).Where("post_id = ?", id).Count(&post.CommentCount)

	// 手动加载 run samples
	if post.Run != nil {
		r.loadRunSamples(ctx, []*model.Run{post.Run})
	}

	return &post, nil
}

func (r *PostRepository) List(ctx context.Context, page, pageSize int) ([]model.Post, int64, error) {
	var posts []model.Post
	var total int64

	db := r.db.WithContext(ctx).Model(&model.Post{}).
		Where("deleted_at IS NULL")
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Order("created_at DESC").Offset(offset).Limit(pageSize).
		Preload("User").Preload("Run").
		Preload("Route", func(db *gorm.DB) *gorm.DB {
			return db.Preload("Points", func(db2 *gorm.DB) *gorm.DB {
				return db2.Order("point_index ASC")
			})
		}).Find(&posts).Error
	if err != nil {
		return nil, 0, err
	}

	// 批量填充点赞数和评论数
	if len(posts) > 0 {
		postIDs := make([]string, len(posts))
		for i, p := range posts {
			postIDs[i] = p.ID
		}
		// 点赞数
		var likeCounts []struct {
			PostID string
			Count  int64
		}
		r.db.WithContext(ctx).Model(&model.PostLike{}).
			Select("post_id, COUNT(*) AS count").
			Where("post_id IN ?", postIDs).
			Group("post_id").
			Find(&likeCounts)
		likeMap := make(map[string]int64, len(likeCounts))
		for _, lc := range likeCounts {
			likeMap[lc.PostID] = lc.Count
		}
		// 评论数
		var commentCounts []struct {
			PostID string
			Count  int64
		}
		r.db.WithContext(ctx).Model(&model.PostComment{}).
			Select("post_id, COUNT(*) AS count").
			Where("post_id IN ?", postIDs).
			Group("post_id").
			Find(&commentCounts)
		commentMap := make(map[string]int64, len(commentCounts))
		for _, cc := range commentCounts {
			commentMap[cc.PostID] = cc.Count
		}
		for i := range posts {
			posts[i].LikeCount = likeMap[posts[i].ID]
			posts[i].CommentCount = commentMap[posts[i].ID]
		}

		// 手动加载每个 post 对应的 run samples
		runPtrs := make([]*model.Run, len(posts))
		for i := range posts {
			runPtrs[i] = posts[i].Run
		}
		r.loadRunSamples(ctx, runPtrs)
	}

	return posts, total, nil
}

// loadRunSamples 手动加载多个 Run 的 GPS 采样数据
// 由于 run_samples 表是分区表，MySQL 不支持分区表的外键
// 因此无法使用 GORM 的 Preload 自动加载，需要手动查询
func (r *PostRepository) loadRunSamples(ctx context.Context, runs []*model.Run) {
	// 收集非空的 runID
	var runIDs []string
	for _, ru := range runs {
		if ru != nil && ru.ID != "" {
			runIDs = append(runIDs, ru.ID)
		}
	}
	if len(runIDs) == 0 {
		return
	}

	// 一次查询加载所有 samples
	var samples []model.RunSample
	r.db.WithContext(ctx).
		Where("run_id IN ?", runIDs).
		Order("sample_time ASC").
		Find(&samples)

	// 按 run_id 分组
	sampleMap := make(map[string][]model.RunSample, len(runIDs))
	for _, s := range samples {
		sampleMap[s.RunID] = append(sampleMap[s.RunID], s)
	}

	// 逐个赋值
	for _, ru := range runs {
		if ru != nil {
			ru.Samples = sampleMap[ru.ID]
		}
	}
}

// ==================== Comment ====================

func (r *PostRepository) CreateComment(ctx context.Context, comment *model.PostComment) error {
	return r.db.WithContext(ctx).Create(comment).Error
}

func (r *PostRepository) ListCommentsByPostID(ctx context.Context, postID string, page, pageSize int) ([]model.PostComment, int64, error) {
	var comments []model.PostComment
	var total int64

	db := r.db.WithContext(ctx).Model(&model.PostComment{}).Where("post_id = ?", postID)
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err := db.Order("created_at DESC").Offset(offset).Limit(pageSize).
		Preload("User").
		Find(&comments).Error
	if err != nil {
		return nil, 0, err
	}

	return comments, total, nil
}

// ==================== Like ====================

func (r *PostRepository) CreateLike(ctx context.Context, like *model.PostLike) error {
	return r.db.WithContext(ctx).Create(like).Error
}

func (r *PostRepository) DeleteLike(ctx context.Context, postID, userID string) error {
	return r.db.WithContext(ctx).
		Where("post_id = ? AND user_id = ?", postID, userID).
		Delete(&model.PostLike{}).Error
}

func (r *PostRepository) CountLikes(ctx context.Context, postID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.PostLike{}).Where("post_id = ?", postID).Count(&count).Error
	return count, err
}

func (r *PostRepository) IsLiked(ctx context.Context, postID, userID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.PostLike{}).
		Where("post_id = ? AND user_id = ?", postID, userID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// CountTodayByUser 统计用户今日已发动态数
func (r *PostRepository) CountTodayByUser(ctx context.Context, userID string, count *int64) error {
	return r.db.WithContext(ctx).Model(&model.Post{}).
		Where("user_id = ? AND DATE(created_at) = CURDATE()", userID).
		Count(count).Error
}






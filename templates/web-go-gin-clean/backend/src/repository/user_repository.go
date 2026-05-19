package repository

import (
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Email string `gorm:"uniqueIndex;not null"`
}

type UserRepository struct {
	DB *gorm.DB
}

func (r *UserRepository) CreateUser(email string) (*User, error) {
	user := &User{Email: email}
	if err := r.DB.Create(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepository) GetAllUsers() ([]User, error) {
	var users []User
	if err := r.DB.Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}
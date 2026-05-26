package controllers

import (
	"net/http"
	"app/src/repository"
	"github.com/gin-gonic/gin"
)

type UserController struct {
	Repo *repository.UserRepository
}

type CreateUserInput struct {
	Email string `json:"email" binding:"required,email"`
}

func (ctrl *UserController) RegisterUser(c *gin.Context) {
	var input CreateUserInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := ctrl.Repo.CreateUser(input.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not register user"})
		return
	}

	c.JSON(http.StatusCreated, user)
}

func (ctrl *UserController) GetUsers(c *gin.Context) {
	users, err := ctrl.Repo.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not fetch users"})
		return
	}
	c.JSON(http.StatusOK, users)
}
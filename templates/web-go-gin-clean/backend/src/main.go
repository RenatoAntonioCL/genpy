package main

import (
	"log"
	"os"
	"{{PROJECT_NAME}}/src/controllers"
	"{{PROJECT_NAME}}/src/repository"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func main() {
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		dsn = "root:root_secure_password@tcp(127.0.0.1:3306)/test_db?charset=utf8mb4&parseTime=True&loc=Local"
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("❌ Failed to connect database: %v", err)
	}

	// Auto-Migración de esquemas
	db.AutoMigrate(&repository.User{})

	userRepo := &repository.UserRepository{DB: db}
	userCtrl := &controllers.UserController{Repo: userRepo}

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "alive", "engine": "gin"})
	})

	r.POST("/users", userCtrl.RegisterUser)
	r.GET("/users", userCtrl.GetUsers)

	log.Println("🚀 Production Web Server active on port :8080")
	r.Run(":8080")
}
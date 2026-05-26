package main

import (
	"fmt"
	"log"
	"os"

	"app/src/controllers"
	"app/src/repository"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func databaseDSN() string {
	if dsn := os.Getenv("DB_DSN"); dsn != "" {
		return dsn
	}
	host := envOr("DB_HOST", "db")
	port := envOr("DB_PORT", "3306")
	user := envOr("DB_USER", "root")
	pass := envOr("DB_PASSWORD", "root")
	name := envOr("DB_NAME", "app")
	return fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		user, pass, host, port, name,
	)
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func main() {
	db, err := gorm.Open(mysql.Open(databaseDSN()), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect database: %v", err)
	}

	if err := db.AutoMigrate(&repository.User{}); err != nil {
		log.Fatalf("failed to migrate: %v", err)
	}

	userRepo := &repository.UserRepository{DB: db}
	userCtrl := &controllers.UserController{Repo: userRepo}

	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "alive", "engine": "gin"})
	})
	r.POST("/users", userCtrl.RegisterUser)
	r.GET("/users", userCtrl.GetUsers)

	log.Println("server listening on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal(err)
	}
}

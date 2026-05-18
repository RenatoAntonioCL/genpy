package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// Response estructura la respuesta JSON del servidor
type Response struct {
	Message string `json:"message"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(Response{
			Message: fmt.Sprintf("Hello from {{PROJECT_NAME}}"),
		})
	})

	log.Printf("{{PROJECT_NAME}} running on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
//go:build unit

package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"go.uber.org/zap/zaptest"
)

func TestHealthHandler(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &Config{
		Host: "localhost",
		Port: "8080",
	}

	server, _ := NewServer(config, logger)
	server.registerHandlers()

	req := httptest.NewRequest("GET", "/health", nil)
	req.Header.Set("User-Agent", "Mozilla/5.0")
	w := httptest.NewRecorder()
	server.router.ServeHTTP(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, resp.StatusCode)
		t.Errorf("Response body: %s", w.Body.String())
	}
}

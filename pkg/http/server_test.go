//go:build unit

package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"go.uber.org/zap/zaptest"
)

func TestNewServer(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &Config{
		Host: "localhost",
		Port: "8080",
	}

	server, err := NewServer(config, logger)
	if err != nil {
		t.Fatalf("Failed to create server: %v", err)
	}

	if server.config != config {
		t.Errorf("Expected server config to be %v, got %v", config, server.config)
	}

	if server.logger != logger {
		t.Errorf("Expected server logger to be %v, got %v", logger, server.logger)
	}
}

func TestServer_StartWithValidPort(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &Config{
		Host: "localhost",
		Port: "8080",
	}

	server, _ := NewServer(config, logger)
	channel := make(chan int, 1)

	testServer := server.ListenAndServe(channel)
	defer testServer.Close()

	if testServer == nil {
		t.Errorf("Expected server to start, got nil")
	}

	select {
	case status := <-channel:
		if status == -1 {
			t.Errorf("Expected server to start successfully, but it crashed")
		}
	default:
		// No crash, server started successfully
	}
}

func TestServer_StartWithPortZero(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &Config{
		Host: "localhost",
		Port: "0",
	}

	server, _ := NewServer(config, logger)
	channel := make(chan int, 1)

	testServer := server.ListenAndServe(channel)

	if testServer != nil {
		t.Errorf("Expected server not to start with port 0, but it did")
	}
}

func TestIndexHandler(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &Config{
		Host:   "localhost",
		Port:   "8080",
		UIPath: "../../kodata",
	}

	server, _ := NewServer(config, logger)
	server.registerHandlers()

	req := httptest.NewRequest("GET", "/", nil)
	req.Header.Set("User-Agent", "Mozilla/5.0")
	w := httptest.NewRecorder()
	server.router.ServeHTTP(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, resp.StatusCode)
		t.Errorf("Response body: %s", w.Body.String())
	}
}

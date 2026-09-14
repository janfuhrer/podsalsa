//go:build unit

package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"go.uber.org/zap/zaptest"
)

// FuzzRouter drives the router with arbitrary methods, targets and User-Agent
// headers. A handler must never panic on untrusted input, and must never answer
// with a 5xx: every request either routes to a handler that succeeds, or is
// rejected by the router with a 4xx.
func FuzzRouter(f *testing.F) {
	seeds := []struct{ method, target, userAgent string }{
		{"GET", "/", "Mozilla/5.0"},
		{"GET", "/health", "Mozilla/5.0"},
		{"GET", "/", "curl/8.7.1"},
		{"POST", "/health", "Mozilla/5.0"},
		{"GET", "/../../../etc/passwd", "Mozilla/5.0"},
		{"GET", "/health?x=%00%01", ""},
		{"GET", "/%2e%2e/", "Mozilla/5.0"},
		{"GET", "/health#frag", "Mozilla/5.0\r\nX-Injected: 1"},
	}
	for _, s := range seeds {
		f.Add(s.method, s.target, s.userAgent)
	}

	logger := zaptest.NewLogger(f)
	server, err := NewServer(&Config{
		Host:   "localhost",
		Port:   "8080",
		UIPath: "../../kodata",
	}, logger)
	if err != nil {
		f.Fatalf("failed to create server: %v", err)
	}
	server.registerHandlers()

	f.Fuzz(func(t *testing.T, method, target, userAgent string) {
		// Inputs that net/http itself refuses to build a request from say
		// nothing about our handlers, so skip them rather than fail.
		if method == "" || strings.ContainsAny(method, " \t\r\n") {
			t.Skip()
		}
		req, err := http.NewRequest(method, "http://example.com"+target, nil)
		if err != nil {
			t.Skip()
		}
		// Header values may not contain control characters.
		if !strings.ContainsAny(userAgent, "\r\n\x00") {
			req.Header.Set("User-Agent", userAgent)
		}

		w := httptest.NewRecorder()
		server.router.ServeHTTP(w, req)

		if code := w.Result().StatusCode; code >= 500 {
			t.Errorf("handler returned %d for method=%q target=%q user-agent=%q",
				code, method, target, userAgent)
		}
	})
}

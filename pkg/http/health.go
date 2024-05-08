package http

import (
	"net/http"
)

func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if _, err := w.Write([]byte(`{"status": "OK"}`)); err != nil {
		http.Error(w, "Failed to write response", http.StatusInternalServerError)
	}
}

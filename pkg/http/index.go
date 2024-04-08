package http

import (
	"html/template"
	"net/http"
)

func (s *Server) indexHandler(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.New("index.html").ParseFiles("./ui/index.html")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("./ui/index.html" + err.Error()))
		return
	}

	data := struct {
		Title      string
		Version    string
		Commit     string
		CommitDate string
	}{
		Title:      s.config.Hostname,
		Version:    s.config.Version,
		Commit:     s.config.Commit,
		CommitDate: s.config.CommitDate,
	}

	if err := tmpl.Execute(w, data); err != nil {
		http.Error(w, "./ui/index.html"+err.Error(), http.StatusInternalServerError)
	}
}

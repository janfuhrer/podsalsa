package http

import (
	"html/template"
	"net/http"
	"path"
)

func (s *Server) indexHandler(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.New("index.html").ParseFiles(path.Join(s.config.UIPath, "index.html"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
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
		http.Error(w, path.Join(s.config.UIPath, "index.html")+err.Error(), http.StatusInternalServerError)
	}
}

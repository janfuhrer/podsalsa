package http

import (
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/zap"
)

type Config struct {
	Hostname  string `mapstructure:"hostname"`
	Host      string `mapstructure:"host"`
	Port      string `mapstructure:"port"`
	Version   string `mapstructure:"version"`
	BuildTime string `mapstructure:"buildTime"`
	Commit    string `mapstructure:"commit"`
	UIPath    string `mapstructure:"uiPath"`
}

type Server struct {
	router  *mux.Router
	config  *Config
	logger  *zap.Logger
	handler http.Handler
}

func NewServer(config *Config, logger *zap.Logger) (*Server, error) {
	srv := &Server{
		router: mux.NewRouter(),
		logger: logger,
		config: config,
	}

	return srv, nil
}

func (s *Server) registerHandlers() {
	s.router.HandleFunc("/", s.indexHandler).HeadersRegexp("User-Agent", "^Mozilla.*").Methods("GET")
	s.router.HandleFunc("/health", s.healthHandler).Methods("GET")
}

func (s *Server) registerMiddlewares() {
	httpLogger := NewLoggingMiddleware(s.logger)
	s.router.Use(httpLogger.Handler)
}

func (s *Server) ListenAndServe(channel chan int) *http.Server {
	s.registerHandlers()
	s.registerMiddlewares()
	s.handler = s.router
	srv := s.startServer(channel)

	return srv
}

func (s *Server) startServer(channel chan int) *http.Server {

	// check if port is specified
	if s.config.Port == "0" {
		return nil
	}

	srv := &http.Server{
		Addr:         s.config.Host + ":" + s.config.Port,
		WriteTimeout: 30 * time.Second,
		ReadTimeout:  30 * time.Second,
		IdleTimeout:  2 * 30 * time.Second,
		Handler:      s.handler,
	}

	// start the server in the background
	go func() {
		s.logger.Info("Starting HTTP Server.", zap.String("addr", srv.Addr))
		if err := srv.ListenAndServe(); err != http.ErrServerClosed {
			s.logger.Fatal("HTTP server crashed", zap.Error(err))
			channel <- -1
		}
	}()

	return srv
}

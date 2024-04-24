package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/spf13/pflag"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"github.com/janfuhrer/podsalsa/pkg/http"
)

// These variables are set in build step
var Version = "v0.0.0-dev.0"
var Commit = "none"
var BuildTime = "unknown"

func main() {
	fs := pflag.NewFlagSet("default", pflag.ContinueOnError)
	fs.String("host", "", "Host to bind service to")
	fs.Int("port", 8080, "Port to bind service to")
	fs.String("level", "info", "Log level debug, info, warn, error, panic, fatal")
	fs.String("ui-path", "kodata", "Path to UI files")

	// Parse the flags
	err := fs.Parse(os.Args[1:])
	switch {
	case err == pflag.ErrHelp:
		os.Exit(0)
	case err != nil:
		fmt.Fprintf(os.Stderr, "error: %v\n", err.Error())
		fs.PrintDefaults()
		os.Exit(2)
	}

	// bind flags and environment variables
	if err := viper.BindPFlags(fs); err != nil {
		fmt.Fprintf(os.Stderr, "error binding flags and environment variables: %v\n", err.Error())
		os.Exit(2)
	}
	hostname, _ := os.Hostname()
	viper.Set("hostname", hostname)
	viper.Set("version", Version)
	viper.Set("commit", Commit)
	viper.Set("buildTime", BuildTime)
	viper.SetEnvPrefix("PODSALSA")
	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	viper.AutomaticEnv()

	// use "KO_DATA_PATH" if set, else use "uiPath" from config
	dataPath := os.Getenv("KO_DATA_PATH")
	if dataPath != "" {
		viper.Set("uiPath", dataPath)
	} else {
		viper.Set("uiPath", viper.GetString("ui-path"))
	}

	// configure logging
	logger, _ := initZap(viper.GetString("level"))
	defer func() {
		if err := logger.Sync(); err != nil {
			fmt.Fprintf(os.Stderr, "error creating logger: %v\n", err.Error())
			os.Exit(2)
		}
	}()
	stdLog := zap.RedirectStdLog(logger)
	defer stdLog()

	// validate port
	if _, err := strconv.Atoi(viper.GetString("port")); err != nil {
		port, _ := fs.GetInt("port")
		viper.Set("port", strconv.Itoa(port))
	}

	// load HTTP server config
	var srvCfg http.Config
	if err := viper.Unmarshal(&srvCfg); err != nil {
		logger.Panic("config unmarshal failed", zap.Error(err))
	}

	// log port
	logger.Info("Starting podsalsa...",
		zap.String("version", Version),
		zap.String("commit", Commit),
		zap.String("buildTime", BuildTime),
		zap.String("port", srvCfg.Port),
		zap.String("uiPath", srvCfg.UIPath),
	)

	// start HTTP server
	channel := make(chan int)

	srv, _ := http.NewServer(&srvCfg, logger)
	httpServer := srv.ListenAndServe(channel)
	if httpServer != nil {
		defer httpServer.Close()
	}

	// wait for shutdown signal
	for range channel {
		logger.Info("Shutting down podsalsa...")
		return
	}
}

func initZap(logLevel string) (*zap.Logger, error) {
	level := zap.NewAtomicLevelAt(zapcore.InfoLevel)
	switch logLevel {
	case "debug":
		level = zap.NewAtomicLevelAt(zapcore.DebugLevel)
	case "info":
		level = zap.NewAtomicLevelAt(zapcore.InfoLevel)
	case "warn":
		level = zap.NewAtomicLevelAt(zapcore.WarnLevel)
	case "error":
		level = zap.NewAtomicLevelAt(zapcore.ErrorLevel)
	case "fatal":
		level = zap.NewAtomicLevelAt(zapcore.FatalLevel)
	case "panic":
		level = zap.NewAtomicLevelAt(zapcore.PanicLevel)
	}

	zapEncoderConfig := zapcore.EncoderConfig{
		TimeKey:        "ts",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.ISO8601TimeEncoder,
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	zapConfig := zap.Config{
		Level:       level,
		Development: false,
		Sampling: &zap.SamplingConfig{
			Initial:    100,
			Thereafter: 100,
		},
		Encoding:         "json",
		EncoderConfig:    zapEncoderConfig,
		OutputPaths:      []string{"stderr"},
		ErrorOutputPaths: []string{"stderr"},
	}

	return zapConfig.Build()
}

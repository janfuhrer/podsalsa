NAME:=podsalsa
DOCKER_REPOSITORY:=janfuhrer
DOCKER_IMAGE_NAME:=$(DOCKER_REPOSITORY)/$(NAME)
GIT_COMMIT:=$(shell git describe --dirty --always)
DATE:=`date +%Y-%m-%d`
VERSION:=0.0.0-dev.0

tidy:
	rm -f go.sum; go mod tidy -compat=1.22

build:
	go build -o $(NAME) -ldflags "-s -w -X main.Version=$(VERSION) -X main.Commit=$(GIT_COMMIT) -X main.CommitDate=$(DATE)" main.go

build-container:
	docker build -t $(DOCKER_IMAGE_NAME):$(VERSION) .

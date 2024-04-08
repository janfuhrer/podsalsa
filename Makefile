NAME:=podsalsa
DOCKER_REPOSITORY:=janfuhrer
DOCKER_IMAGE_NAME:=$(DOCKER_REPOSITORY)/$(NAME)
GIT_COMMIT:=$(shell git describe --dirty --always)
VERSION:=0.0.1

tidy:
	rm -f go.sum; go mod tidy -compat=1.22

build-container:
	docker build -t $(DOCKER_IMAGE_NAME):$(VERSION) .

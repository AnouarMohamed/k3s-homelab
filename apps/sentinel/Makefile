SHELL := /usr/bin/env bash
.PHONY: all test lint build clean

all: lint test build

test:
	go test -v -race -cover ./...

lint:
	go vet ./...

build:
	@mkdir -p bin
	CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin/sentinel-api ./cmd/api
	CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o bin/sentinel-worker ./cmd/worker

clean:
	rm -rf bin


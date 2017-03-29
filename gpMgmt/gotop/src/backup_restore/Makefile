SHELL := /bin/bash
.DEFAULT_GOAL := test
MODULE_NAME=gpbackup
DIR_PATH=$(shell dirname `pwd`)

.PHONY : build

DEST = .

GOFLAGS := -o $(DEST)

export GOPATH := $(DIR_PATH)/..
export PATH := $(PATH):$(GOPATH)/bin

dependencies :
		go get github.com/onsi/ginkgo/ginkgo
		go get golang.org/x/tools/cmd/goimports
		go get github.com/maxbrunsfeld/counterfeiter
		go get github.com/onsi/gomega
#		go get 	"gopkg.in/DATA-DOG/go-sqlmock.v1"

		go get

format : dependencies
		goimports -w .
		go fmt .

ginkgo : dependencies
		ginkgo -r -randomizeSuites -randomizeAllSpecs -race 2>&1

test : format ginkgo

ci : ginkgo

build :
		mkdir -p build
		go build $(GOFLAGS) -o $(GOPATH)/bin/$(MODULE_NAME)
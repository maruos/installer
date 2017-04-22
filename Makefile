BINARY=installer
VERSION=$(shell git describe --always --dirty)
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

ZIP_PREFIX=maru-installer-$(VERSION)
ZIP_ASSETS=HELP.txt
ZIP_FLAGS=-X --junk-paths

all: linux darwin windows

linux:
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer bin/$@/* $(ZIP_ASSETS)

darwin:
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer bin/mac/* $(ZIP_ASSETS)

windows:
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer.exe bin/$@/* $(ZIP_ASSETS)

clean:
	-rm $(ZIP_PREFIX)*.zip

.PHONY: linux darwin windows

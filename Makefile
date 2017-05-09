BINARY=installer
VERSION=$(shell git describe --always --dirty)
LDFLAGS=-ldflags "-X main.Version=$(VERSION)"

DIST_DIR=dist
ZIP_PREFIX=$(DIST_DIR)/maru-installer-$(VERSION)
ZIP_ASSETS=HELP.txt
ZIP_FLAGS=-X --junk-paths

all: linux darwin windows default

default:
	go build $(LDFLAGS)

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

linux: $(DIST_DIR)
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer bin/$@/* $(ZIP_ASSETS)

darwin: $(DIST_DIR)
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer bin/mac/* $(ZIP_ASSETS)

windows: $(DIST_DIR)
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer.exe bin/$@/* $(ZIP_ASSETS)

clean:
	-if [ -f installer ] ; then rm installer; fi
	-if [ -f installer.exe ] ; then rm installer.exe; fi
	-if [ -d $(DIST_DIR) ] ; then rm -r $(DIST_DIR); fi

.PHONY: default all linux darwin windows

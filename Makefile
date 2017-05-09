#
# Copyright 2017 The Maru OS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer prebuilts/$@/* $(ZIP_ASSETS)

darwin: $(DIST_DIR)
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	cp prebuilts/linux/uninstall.sh prebuilts/mac/uninstall
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer prebuilts/mac/* $(ZIP_ASSETS)
	rm prebuilts/mac/uninstall

windows: $(DIST_DIR)
	GOOS=$@ GOARCH=amd64 go build $(LDFLAGS)
	zip $(ZIP_FLAGS) $(ZIP_PREFIX)-$@.zip installer.exe prebuilts/$@/* $(ZIP_ASSETS)

clean:
	-if [ -f installer ] ; then rm installer; fi
	-if [ -f installer.exe ] ; then rm installer.exe; fi
	-if [ -d $(DIST_DIR) ] ; then rm -r $(DIST_DIR); fi

.PHONY: default all linux darwin windows

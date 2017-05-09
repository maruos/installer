//
// Copyright 2017 The Maru OS Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

package android

import (
	"os/exec"
)

// AndroidDeviceTool represents a program for interacting with Android devices.
type AndroidDeviceTool interface {
	DeviceConnected() bool
}

// AndroidDeviceStatus represents the main device states that are relevant to
// an AndroidDeviceTool.
type AndroidDeviceStatus uint8

const (
	NoDeviceFound AndroidDeviceStatus = iota
	NoUsbPerms
	DeviceUnauthorized
	DeviceConnected
)

// BinaryAndroidTool represents an AndroidDeviceTool that is run as a binary program.
type BinaryAndroidTool struct {
	Name string
}

func (b *BinaryAndroidTool) Run(args ...string) (string, error) {
	out, err := exec.Command(b.Name, args...).CombinedOutput()
	return string(out), err
}

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

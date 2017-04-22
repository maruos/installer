// Wrapper around an adb binary.

package android

import (
	"strings"
)

type AdbError struct {
	Output string
	Err    error
}

func (e *AdbError) Error() string {
	return "adb: " + e.Err.Error()
}

func NewAdbError(output string, err error) *AdbError {
	return &AdbError{output, err}
}

type AdbClient struct {
	BinaryAndroidTool
}

func NewAdbClient() AdbClient {
	return AdbClient{BinaryAndroidTool{"adb"}}
}

func (a *AdbClient) Status() (AndroidDeviceStatus, error) {
	output, err := a.Run("devices")
	if err != nil {
		return NoDeviceFound, NewAdbError(output, err)
	}

	lines := strings.Split(output, AdbLineSeperator)

	// first line is always "List of devices attached" so we examine the second
	// line
	if len(lines[1]) == 0 {
		return NoDeviceFound, nil
	} else if strings.Contains(output, "no permissions") {
		return NoUsbPerms, nil
	} else if strings.Contains(output, "unauthorized") {
		return DeviceUnauthorized, nil
	} else {
		return DeviceConnected, nil
	}
}

func (a *AdbClient) Push(local, remote string) (err error) {
	output, err := a.Run("push", local, remote)
	if err != nil {
		return NewAdbError(output, err)
	}
	return err
}

func (a *AdbClient) Reboot(image string) (err error) {
	output, err := a.Run("reboot", image)
	if err != nil {
		return NewAdbError(output, err)
	}
	return err
}

func (a *AdbClient) Shell(cmd string) (err error) {
	output, err := a.Run("shell", cmd)
	if err != nil {
		return NewAdbError(output, err)
	}
	return err
}

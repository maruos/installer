package remote

import (
	"github.com/pdsouza/toolbox.go/net"
)

type ReleaseServer interface {
	RequestLatestRelease(device string) (*net.DownloadRequest, error)
}

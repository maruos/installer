package remote

import "github.com/pdsouza/toolbox.go/net"

const (
	TWRPEndpoint      = "https://dl.twrp.me"
	TWRPVersionPrefix = "twrp-3.1.0-0-"
	TWRPExtension     = ".img"
)

func genTWRPDeviceUrl(device string) string {
	return TWRPEndpoint + "/" + device + "/" + TWRPVersionPrefix + device + TWRPExtension
}

func RequestTWRP(device string) (req *net.DownloadRequest, err error) {
	url := genTWRPDeviceUrl(device)

	req, err = net.NewDownloadRequest(url)
	if err != nil {
		return nil, err
	}

	// TWRP looks for referer header to initiate download
	req.Request.Header.Add("Referer", url)

	return req, nil
}

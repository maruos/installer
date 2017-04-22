package remote

import (
	"encoding/json"
	"fmt"
	"github.com/pdsouza/toolbox.go/net"
	"io/ioutil"
	"net/http"
	"strings"
)

const (
	Endpoint = "https://api.github.com"
	Org      = "maruos"
	Repo     = "maruos"
)

// GRelease models a release returned by the GitHub API.
//
// Note that only essential fields are included; the json package
// will only decode these fields.
type GRelease struct {
	Url      string
	Tag_Name string
	Draft    bool
	Assets   []GAsset
}

// GAsset models an asset within a GitHub release.
type GAsset struct {
	Name                 string
	Size                 int
	Browser_Download_Url string
}

type GitHubClient struct {
	endpoint string
}

func NewGitHubClient() ReleaseServer {
	return &GitHubClient{Endpoint}
}

func (g *GitHubClient) RequestLatestRelease(device string) (req *net.DownloadRequest, err error) {
	releases, err := g.getReleases(Org, Repo)
	if err != nil {
		return nil, err
	}

	matchString := "update-" + device
	var latestUpdate GAsset

	// Empirically, the GitHub API always returns releases ordered from newest
	// to oldest, so we can optimize a little by bailing on the first match.
	for _, release := range releases {
		if release.Draft {
			continue
		}
		matches := g.searchReleaseAssets(release, matchString)
		if len(matches) > 0 {
			latestUpdate = matches[0]
			break
		}
	}

	if latestUpdate.Browser_Download_Url == "" {
		return nil, fmt.Errorf("github: no release found for device: %q", device)
	}

	req, err = net.NewDownloadRequest(latestUpdate.Browser_Download_Url)
	return req, err
}

func (g *GitHubClient) getReleases(org, repo string) ([]GRelease, error) {
	url := fmt.Sprintf("%s/repos/%s/%s/releases", g.endpoint, org, repo)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)

	var releases []GRelease
	err = json.Unmarshal(body, &releases)
	if err != nil {
		return nil, err
	}

	return releases, nil
}

func (g *GitHubClient) searchReleaseAssets(release GRelease, match string) []GAsset {
	res := make([]GAsset, 0)
	for _, asset := range release.Assets {
		if strings.Contains(asset.Name, match) {
			res = append(res, asset)
		}
	}
	return res
}

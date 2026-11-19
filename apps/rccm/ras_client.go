package main

import (
	"bytes"
	"encoding/json/v2"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"uuid"

	"k8s.io/klog/v2"
)

type RasClient struct {
	baseUrl *url.URL
}

func NewRasClient() RasClient {
	baseUrl, err := url.Parse("https://ras.i.ramona.fun/")
	if err != nil {
		panic("failed to parse the base url for ras")
	}

	return RasClient{
		baseUrl: baseUrl,
	}
}

type HostStateV2 struct {
	Id     uuid.UUID `json:"id"`
	MainIp net.IP    `json:"main_ip"`
	Zone   string    `json:"zone"`
	Region string    `json:"region"`
}

func (c *RasClient) GetHost(name string) (*HostStateV2, error) {
	base_url, err := url.Parse(fmt.Sprintf("/hosts/%s", name))
	if err != nil {
		return nil, err
	}
	url := c.baseUrl.ResolveReference(base_url)

	response, err := http.Get(url.String())
	if err != nil {
		return nil, err
	}

	state := HostStateV2{}
	err = json.UnmarshalRead(response.Body, &state)

	if err != nil {
		return nil, err
	}

	return &state, nil
}

type Route struct {
	Id             uuid.UUID `json:"id"`
	TargetHostname string    `json:"target_hostname"`
	TargetIps      []string  `json:"target_ips"`
	TargetCidr     string    `json:"target_cidr"`
	Blackhole      bool      `json:"blackhole"`
}

type GetRoutesResponse struct {
	Routes []Route `json:"routes"`
}

func (c *RasClient) makeUrl(path string) (*string, error) {
	base_url, err := url.Parse(path)
	if err != nil {
		return nil, err
	}

	url := c.baseUrl.ResolveReference(base_url)

	url_string := url.String()
	return &url_string, nil
}

func (c *RasClient) GetRoutes() (*GetRoutesResponse, error) {
	url, err := c.makeUrl("/routing/routes")
	if err != nil {
		return nil, err
	}

	response, err := http.Get(*url)
	if err != nil {
		return nil, err
	}

	state := GetRoutesResponse{}
	err = json.UnmarshalRead(response.Body, &state)

	if err != nil {
		return nil, err
	}

	return &state, nil
}

func (c *RasClient) PostRoute(route Route) error {
	url, err := c.makeUrl("/routing/routes")
	if err != nil {
		return err
	}

	json, err := json.Marshal(route)
	if err != nil {
		return err
	}

	klog.Infof("create route request: %v", string(json[:]))
	_, err = http.Post(*url, "application/json", bytes.NewBuffer(json))
	if err != nil {
		return err
	}

	return nil
}

func (c *RasClient) DeleteRoute(id uuid.UUID) error {
	url, err := c.makeUrl(fmt.Sprintf("/routing/routes/%v", id))
	if err != nil {
		return err
	}

	req, err := http.NewRequest("DELETE", *url, nil)
	if err != nil {
		return err
	}

	_, err = http.DefaultClient.Do(req)

	return err
}

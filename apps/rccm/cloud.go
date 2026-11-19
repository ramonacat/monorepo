package main

import (
	"context"
	"errors"
	"fmt"
	"net"
	"uuid"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/types"
	cloudprovider "k8s.io/cloud-provider"
	"k8s.io/klog/v2"
)

type cloud struct{}

func NewCloud() (cloudprovider.Interface, error) {
	return &cloud{}, nil
}

func (c *cloud) Initialize(ccb cloudprovider.ControllerClientBuilder, stop <-chan struct{}) {}

func (c *cloud) LoadBalancer() (cloudprovider.LoadBalancer, bool) {
	return nil, false
}

func (c *cloud) Instances() (cloudprovider.Instances, bool) {
	return nil, false
}

func (c *cloud) InstancesV2() (cloudprovider.InstancesV2, bool) {
	return &instances{}, true
}

func (c *cloud) Zones() (cloudprovider.Zones, bool) {
	return nil, false
}

func (c *cloud) Clusters() (cloudprovider.Clusters, bool) {
	return nil, false
}

func (c *cloud) Routes() (cloudprovider.Routes, bool) {
	return &routes{}, true
}

func (c *cloud) ProviderName() string { return "ramona" }

func (c *cloud) HasClusterID() bool {
	return true
}

type instances struct{}

func (c *instances) InstanceExists(ctx context.Context, node *v1.Node) (bool, error) {
	addrs, err := net.LookupHost(fmt.Sprintf("%v.devices.i.ramona.fun", node.Name))

	if err != nil {
		if dnserror, ok := err.(*net.DNSError); ok && dnserror.IsNotFound {
			return false, nil
		}

		return false, err
	}

	for _, addr := range addrs {
		ip := net.ParseIP(addr)

		if ip == nil {
			klog.Warningf("failed to parse IP %v", ip)
			continue
		}

		if ip.To4() != nil {
			return true, nil
		}
	}

	return false, errors.New("failed to find ipv4 for this host")
}

// InstanceMetadata implements [cloudprovider.InstancesV2].
func (c *instances) InstanceMetadata(ctx context.Context, node *v1.Node) (*cloudprovider.InstanceMetadata, error) {
	client := NewRasClient()
	host, err := client.GetHost(node.Name)
	if err != nil {
		return nil, err
	}

	return &cloudprovider.InstanceMetadata{
		ProviderID:    host.Id.String(),
		InstanceType:  "notype",
		NodeAddresses: []v1.NodeAddress{{Type: "InternalIP", Address: host.MainIp.String()}},
		Zone:          host.Zone,
		Region:        host.Region,
	}, nil
}

// InstanceShutdown implements [cloudprovider.InstancesV2].
func (c *instances) InstanceShutdown(ctx context.Context, node *v1.Node) (bool, error) {
	return false, errors.ErrUnsupported
}

type routes struct{}

// CreateRoute implements [cloudprovider.Routes].
func (r *routes) CreateRoute(ctx context.Context, clusterName string, nameHint string, route *cloudprovider.Route) error {
	klog.Infof("creating route: %v", route)
	var targetIps []string

	for _, address := range route.TargetNodeAddresses {
		if address.Type == "InternalIP" || address.Type == "ExternalIP" {
			targetIps = append(targetIps, address.Address)
		}
	}

	_, destination_cidr, err := net.ParseCIDR(route.DestinationCIDR)
	if err != nil {
		return err
	}

	if destination_cidr == nil {
		return fmt.Errorf("invalid cidr: %v", route.DestinationCIDR)
	}

	client := NewRasClient()
	err = client.PostRoute(Route{
		Id:             uuid.NewV7(),
		TargetHostname: string(route.TargetNode),
		TargetIps:      targetIps,
		TargetCidr:     destination_cidr.String(),
		Blackhole:      route.Blackhole,
	})

	return err
}

// DeleteRoute implements [cloudprovider.Routes].
func (r *routes) DeleteRoute(ctx context.Context, clusterName string, route *cloudprovider.Route) error {
	client := NewRasClient()

	id, err := uuid.Parse(route.Name)
	if err != nil {
		return err
	}

	err = client.DeleteRoute(id)
	if err != nil {
		return err
	}

	return nil
}

// ListRoutes implements [cloudprovider.Routes].
func (r *routes) ListRoutes(ctx context.Context, clusterName string) ([]*cloudprovider.Route, error) {
	client := NewRasClient()

	routes, err := client.GetRoutes()
	if err != nil {
		return nil, err
	}

	result := make([]*cloudprovider.Route, len(routes.Routes))

	for i, route := range routes.Routes {
		addresses := make([]v1.NodeAddress, len(route.TargetIps))
		for j, ip := range route.TargetIps {
			addresses[j] = v1.NodeAddress{
				// TODO support external IPs as well
				Type:    "InternalIP",
				Address: ip,
			}
		}

		addresses = append(addresses, v1.NodeAddress{Type: "Hostname", Address: route.TargetHostname})

		result[i] = &cloudprovider.Route{
			Name:                route.Id.String(),
			TargetNode:          types.NodeName(route.TargetHostname),
			EnableNodeAddresses: true,
			TargetNodeAddresses: addresses,
			DestinationCIDR:     route.TargetCidr,
			Blackhole:           route.Blackhole,
		}
	}

	return result, nil
}

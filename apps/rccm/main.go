package main

import (
	"os"

	"k8s.io/apimachinery/pkg/util/wait"
	cloudprovider "k8s.io/cloud-provider"
	"k8s.io/cloud-provider/app"
	"k8s.io/cloud-provider/app/config"
	"k8s.io/cloud-provider/names"
	"k8s.io/cloud-provider/options"
	"k8s.io/component-base/cli"
	cliflag "k8s.io/component-base/cli/flag"
	"k8s.io/klog/v2"
)

func main() {
	ccmOptions, err := options.NewCloudControllerManagerOptions()
	if err != nil {
		klog.Errorf("unable to initialize command options: %v", err)

		return
	}

	fss := cliflag.NamedFlagSets{}
	command := app.NewCloudControllerManagerCommand(ccmOptions, cloudInitializer, controllerInitializers(), names.CCMControllerAliases(), fss, wait.NeverStop)
	code := cli.Run(command)

	os.Exit(code)
}

func controllerInitializers() map[string]app.ControllerInitFuncConstructor {
	controllerInitializers := app.DefaultInitFuncConstructors
	if constructor, ok := controllerInitializers[names.CloudNodeController]; ok {
		constructor.InitContext.ClientName = "ramona-external-cloud-node-controller"
		controllerInitializers[names.CloudNodeController] = constructor
	}
	if constructor, ok := controllerInitializers[names.CloudNodeLifecycleController]; ok {
		constructor.InitContext.ClientName = "ramona-external-cloud-node-lifecycle-controller"
		controllerInitializers[names.CloudNodeLifecycleController] = constructor
	}
	if constructor, ok := controllerInitializers[names.ServiceLBController]; ok {
		constructor.InitContext.ClientName = "ramona-external-service-controller"
		controllerInitializers[names.ServiceLBController] = constructor
	}
	if constructor, ok := controllerInitializers[names.NodeRouteController]; ok {
		constructor.InitContext.ClientName = "ramona-external-route-controller"
		controllerInitializers[names.NodeRouteController] = constructor
	}
	return controllerInitializers
}

func cloudInitializer(config *config.CompletedConfig) cloudprovider.Interface {
	// initialize cloud provider with the cloud provider name and config file provided
	cloud, err := NewCloud()
	if err != nil {
		klog.Fatalf("Cloud provider could not be initialized: %v", err)
	}
	if cloud == nil {
		klog.Fatalf("Cloud provider is nil")
	}

	if !cloud.HasClusterID() {
		if config.ComponentConfig.KubeCloudShared.AllowUntaggedCloud {
			klog.Warning("detected a cluster without a ClusterID.  A ClusterID will be required in the future.  Please tag your cluster to avoid any future issues")
		} else {
			klog.Fatalf("no ClusterID found.  A ClusterID is required for the cloud provider to function properly.  This check can be bypassed by setting the allow-untagged-cloud option")
		}
	}
	return cloud
}

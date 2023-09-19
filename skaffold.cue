package scidev

config: {
	apiVersion: "skaffold/v4beta6"
	kind:       "Config"
	manifests: rawYaml: [
		"cluster/resources/namespace.yaml",
		"cluster/resources/pvc.yaml",
		"cluster/resources/deployment.yaml",
	]
	deploy: kubectl: defaultNamespace: "scidev"
	build: artifacts: [{
		image: "ghcr.io/sciexp/scidev"
		docker: dockerfile: "containerfiles/Containerfile.scidev"
	}]
	profiles: [{
		name: "dev"
		deploy: statusCheckDeadlineSeconds: 960
	}]
}

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
	build: {
		artifacts: [{
			// - image: ghcr.io/sciexp/scidev
			//   docker:
			//     dockerfile: containers/Containerfile.scidev
			// - image: us-central1-docker.pkg.dev/sciexp/scidev/scipod
			//   docker:
			//     dockerfile: containers/Containerfile.scipod
			image: "ghcr.io/sciexp/scipod"
			kaniko: {
				dockerfile: "containers/Containerfile.scipod"
				cache: {
					ttl:             "168h"
					cacheCopyLayers: true
				}
			}
		}]
		tagPolicy: sha256: {}

		cluster: {
			namespace: "scidev"
			// With GCP credentials
			// pullSecretPath: ./kaniko-key.json
			// pullSecretName: kaniko-secret
			// if private, with docker-style credentials
			// pullSecretName: regcred
			// randomPullSecret: true
			// docker-style push credentials
			dockerConfig: {
				path: "./docker-config.json"
			}
			resources: {
				requests: {
					cpu:    "8"
					memory: "16Gi"
				}
				limits: {
					cpu:    "32"
					memory: "180Gi"
				}
			}
			concurrency: 5
		}
	}

	profiles: [{
		name: "dev"
		deploy: statusCheckDeadlineSeconds: 960
	}]
}

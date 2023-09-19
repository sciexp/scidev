package scidev

deployment: scidev: {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "scidev"
		namespace: "scidev"
	}
	spec: {
		replicas: 1
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 1
			}
		}
		selector: matchLabels: app: "scidev"
		template: {
			metadata: labels: app: "scidev"
			spec: {
				containers: [{
					name:            "dev"
					image:           "ghcr.io/sciexp/scidev"
					imagePullPolicy: "IfNotPresent"
					command: ["/bin/sh", "-c", "sleep infinity"]
					resources: {
						requests: {
							cpu:    "16"
							memory: "64Gi"
						}
						limits: {
							cpu:              "30"
							memory:           "96Gi"
							"nvidia.com/gpu": "1"
						}
					}
					volumeMounts: [{
						name:      "scidev"
						mountPath: "/workspace"
					}]
				}]

				nodeSelector: "gpu-type": "nvidia-tesla-t4"

				volumes: [{
					name: "scidev"
					persistentVolumeClaim: claimName: "scidev-claim"
				}]
			}
		}
	}
}

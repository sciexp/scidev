package kube

deployment: scidev: spec: {
	strategy: rollingUpdate: {
	}
	template: spec: {
		containers: [{
			name:            "scidev"
			image:           #FQImageName
			imagePullPolicy: "IfNotPresent"
			command: ["/bin/sh", "-c", "sleep infinity"]
			resources: {
				requests: {
					cpu:    #CPUNumber
					memory: #MemoryType
				}
				limits: {
					cpu:              *"30" | #CPUNumber
					memory:           *"96Gi" | #MemoryType
					"nvidia.com/gpu": #GPUNumber
				}
			}
			volumeMounts: [{
				name:      "scidev"
				mountPath: "/workspace"
			}]
		}]
		nodeSelector: "gpu-type": #GPUNodeSelectorType
		volumes: [{
			name: "scidev"
			persistentVolumeClaim: claimName: "scidev"
		}]
	}
}

#FQImageName:         *"ghcr.io/sciexp/scidev" | string
#CPUNumber:           *"16" | =~"^[1-9][0-9]{0,1}$"
#MemoryType:          *"64Gi" | =~"^[2-5]?[0-9]{1,2}Gi$"
#GPUNumber:           *"1" | =~"^[1-8]$"
#GPUNodeSelectorType: *"nvidia-tesla-t4" | "nvidia-tesla-a100" | "nvidia-l4" | "" | string

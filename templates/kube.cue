package kube

namespace: [ID=_]: {
	apiVersion: "v1"
	kind:       "Namespace"
	metadata: {
		name: ID
		labels: component: #Component
	}
}

persistentVolumeClaim: [ID=_]: {
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      ID
		namespace: ID
		labels: component: #Component
	}
	spec: {
		accessModes: [...string]
		resources: requests: storage: string
		storageClassName?: string
		volumeMode?:       *"Filesystem" | "Block"
	}
}

deployment: [ID=_]: {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      ID
		namespace: ID
		labels: component: #Component
	}
	spec: {
		replicas:  *1 | int
		strategy?: #Strategy
		selector: matchLabels: app: ID
		template: {
			metadata: labels: {
				app:        ID
				domain?:    *"dev" | string
				component?: #Component
			}
			spec: {
				containers: [...#Container]
				nodeSelector?: [string]: string
				volumes?: [...#Volume]
			}
		}
	}
}

#Component: string

#Strategy: {
	type: *"RollingUpdate" | string
	rollingUpdate?: {
		maxSurge:       *1 | int
		maxUnavailable: *1 | int
	}
}

#Container: {
	name:             string
	image:            string
	imagePullPolicy?: *"IfNotPresent" | string
	command?: [...string]
	resources?: #Resources
	volumeMounts?: [...#VolumeMount]
	ports?: [...#Port]
}

#Port: {
	containerPort: >=0 & <=65535
	name?:         string
	protocol?:     *"TCP" | "UDP"
}

#Resources: {
	requests: {
		cpu:    string
		memory: string
	}
	limits: {
		cpu:               string
		memory:            string
		"nvidia.com/gpu"?: string
	}
}

#VolumeMount: {
	name:      string
	mountPath: string
	subPath?:  string
}

#Volume: {
	name: string
	persistentVolumeClaim?: claimName: string
	secret?: secretName:               string
	configMap?: name:                  string
}

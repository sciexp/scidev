package scidev

persistentVolumeClaim: "scidev-claim": {
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "scidev-claim"
		namespace: "scidev"
	}
	spec: {
		accessModes: [
			"ReadWriteOnce",
		]
		resources: requests: storage: "400Gi"
		storageClassName: "standard-rwo"
		volumeMode:       "Filesystem"
	}
}

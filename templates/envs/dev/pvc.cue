package kube

persistentVolumeClaim: scidev: spec: {
	accessModes: ["ReadWriteOnce"]
	resources: requests: storage: "400Gi"
	storageClassName: "standard-rwo"
	volumeMode:       "Filesystem"
}

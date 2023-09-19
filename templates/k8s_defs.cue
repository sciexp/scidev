package kube

import (
	"k8s.io/api/core/v1"
	apps_v1 "k8s.io/api/apps/v1"
)

namespace: [string]:             v1.#Namespace
persistentVolumeClaim: [string]: v1.#PersistentVolumeClaim
deployment: [string]:            apps_v1.#Deployment

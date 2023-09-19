package kube

objects: [ for v in objectSets for x in v {x}]

objectSets: [
	namespace,
	deployment,
	persistentVolumeClaim,
]

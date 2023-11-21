#!/usr/bin/env bash

set -Eeuo pipefail
# set -x

#------
# setup
#------

# connect to remote zen instance
zen connect \
  --url "${ZEN_SERVER_URL}" \
  --username "${ZEN_SERVER_USERNAME}" \
  --password "${ZEN_SERVER_PASSWORD}"
zen status

# set kubeflow kube context
kubectl config current-context
kubectl config use-context "${KUBEFLOW_KUBE_CONTEXT}"
kubectl config current-context

zen service-connector describe kubeflow-cluster || \
zen service-connector register kubeflow-cluster \
  --type kubernetes \
  --auto-configure
zen service-connector update kubeflow-cluster \
  --description "Kubeflow cluster" \
  --label auto=true \
  --label purpose=kubeflow
zen service-connector verify kubeflow-cluster

# set kube context
kubectl config current-context
kubectl config use-context "${ZEN_KUBE_CONTEXT}"
kubectl config current-context

# setup gcp service connector
# requires GOOGLE_APPLICATION_CREDENTIALS to specify
# the path to a service account key json file
zen service-connector describe gcp-multi-type || \
zen service-connector register gcp-multi-type \
  --type gcp \
  --auth-method service-account \
  --project_id="${GCP_PROJECT_ID}" \
  --auto-configure
zen service-connector update gcp-multi-type \
  --description "Multipurpose GCP connector" \
  --label auto=true \
  --label purpose=multi
zen service-connector verify gcp-multi-type

#--------------------------
# register stack components
#--------------------------

# register container-registry
gcloud auth configure-docker "${ZEN_CONTAINER_REGISTRY_PREFIX}"
zen container-registry describe gcp-registry || \
zen container-registry register \
  gcp-registry --flavor=gcp \
  --uri="${ZEN_CONTAINER_REGISTRY_URI}"
zen container-registry connect gcp-registry --connector gcp-multi-type

# register artifact-store
zen artifact-store describe gcp-store || \
zen artifact-store register \
  gcp-store --flavor=gcp \
  --path="${ZEN_ARTIFACT_STORE_PATH}"
zen artifact-store connect gcp-store --connector gcp-multi-type

# register image-builder
zen image-builder describe kaniko || \
zen image-builder register kaniko \
  --flavor=kaniko \
  --kubernetes_context="${ZEN_KUBE_CONTEXT}" \
  --kubernetes_namespace="kaniko" \
  --service_account_name="kaniko" \
  --executor_args='["--compressed-caching=false", "--use-new-run=true", "--snapshot-mode=redo"]'


# register data validator
zen data-validator describe deepchecks-data-validator || \
zen data-validator register deepchecks-data-validator \
  --flavor=deepchecks

# register experiment-tracker
zen secret get mlflow_secret || \
zen secret create mlflow_secret -v \
"{\"tracking_username\": \"${MLFLOW_TRACKING_USERNAME}\", \"tracking_password\": \"${MLFLOW_TRACKING_PASSWORD}\"}"

zen experiment-tracker describe mlflow || \
zen experiment-tracker register mlflow \
  --flavor=mlflow \
  --tracking_insecure_tls=true \
  --tracking_uri="${MLFLOW_TRACKING_URI}" \
  --tracking_username="{{mlflow_secret.tracking_username}}" \
  --tracking_password="{{mlflow_secret.tracking_password}}"

# register model-registry
# https://github.com/zen-io/zen/blame/0.44.3/docs/book/stacks-and-components/component-guide/model-registries/mlflow.md#L62-L63
zen model-registry describe mlflow || \
zen model-registry register mlflow \
  --flavor=mlflow

# register model-deployer
# https://github.com/zen-io/zen/blame/0.44.3/docs/book/stacks-and-components/component-guide/model-deployers/mlflow.md#L13-L14
# zen model-deployer describe mlflow || \
# zen model-deployer register mlflow \
#   --flavor=mlflow

# register pipeline orchestrator
zen orchestrator describe kubeflow || \
zen orchestrator register kubeflow \
  --flavor=kubeflow \
  --kubeflow_hostname="${KUBEFLOW_HOSTNAME}"
zen orchestrator connect kubeflow --connector kubeflow-cluster

#--------------------------
# register integrated stack
#--------------------------

zen stack describe "${ZEN_STACK_NAME}" || \
zen stack register "${ZEN_STACK_NAME}" \
  --container_registry=gcp-registry \
  --artifact-store=gcp-store \
  --image_builder=kaniko \
  --data_validator=deepchecks_data_validator \
  --experiment_tracker=mlflow \
  --model_registry=mlflow \
  --orchestrator=kubeflow
  # --model_deployer=mlflow \

zen stack set "${ZEN_STACK_NAME}"

# to reregister a component, such as image-builder
#
# remove the component from the stack
# delete the component
# execute the relevant component registration command 
# add it back to the stack
#
# zen stack list
# zen stack remove-component -i "${ZEN_STACK_NAME}"
# zen image-builder delete kaniko
# zen image-builder describe kaniko || \
# zen image-builder register kaniko \
#   --flavor=kaniko \
#   --kubernetes_context="${ZEN_KUBE_CONTEXT}" \
#   --kubernetes_namespace="kaniko" \
#   --service_account_name="kaniko" \
#   --executor_args='["--compressed-caching=false", "--use-new-run=true", "--snapshot-mode=redo"]'
# zen stack update -i kaniko "${ZEN_STACK_NAME}"
# zen image-builder describe kaniko
# zen stack list

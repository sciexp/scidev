# Default command when 'just' is run without arguments
# Run 'just <command>' to execute a command.
default: list

# Display help
help:
  @printf "\nSee Makefile targets for just and direnv installation."
  @printf "\nRun 'just -n <command>' to print what would be executed...\n\n"
  @just --list --unsorted
  @echo "\n...by running 'just <command>'.\n"
  @echo "This message is printed by 'just help'."
  @echo "Just 'just' will just list the available recipes.\n"

# List just recipes
list:
  @just --list --unsorted

# List evaluated just variables
vars:
  @just --evaluate

builder := env_var_or_default('BUILDER', 'podman')
container_user := "runner"
container_home := "/home" / container_user
container_work := container_home / "work"
gcp_project_id := env_var_or_default('GCP_PROJECT_ID', 'sciexp')
git_username := env_var_or_default('GITHUB_USERNAME', 'sciexp')
git_org_name := env_var_or_default('GITHUB_ORG_NAME', 'sciexp')
git_repo_name := env_var_or_default('GITHUB_REPO_NAME', 'scidev')
git_branch_name := env_var_or_default('GITHUB_BRANCH_NAME', 'master')
container_registry := "ghcr.io/" + git_org_name + "/"
pod_accelerator_type := env_var_or_default('POD_ACCELERATOR_TYPE', 'nvidia-tesla-t4')
accelerator_node_selector := "gpu-type=" + pod_accelerator_type

container_type := "dev" # or "app"
container_image := if container_type == "dev" {
    "scidevgpu"
  } else if container_type == "app" {
    "scidevapp"
  } else {
    error("container_type must be either 'dev' or 'app'")
  }
container_tag := "latest"

pod_source_type := env_var_or_default('POD_SOURCE_TYPE', 'git')
pod_git_provider := env_var_or_default('POD_GIT_PROVIDER', 'github')
pod_disk_size := env_var_or_default('POD_DISK_SIZE', '400Gi')
pod_min_cpu := env_var_or_default('POD_MIN_CPU', '16')
pod_min_mem := env_var_or_default('POD_MIN_MEM', '64Gi')
pod_max_cpu := env_var_or_default('POD_MAX_CPU', '32')
pod_max_mem := env_var_or_default('POD_MAX_MEM', '96Gi')
pod_max_accel := env_var_or_default('POD_MAX_ACCEL', '1')
pod_resources := "requests.cpu=" + pod_min_cpu + ",requests.memory=" + pod_min_mem + ",limits.cpu=" + pod_max_cpu + ",limits.memory=" + pod_max_mem + ",limits.nvidia.com/gpu=" + pod_max_accel

architecture := if arch() == "x86_64" {
    "amd64"
  } else if arch() == "aarch64" {
    "arm64"
  } else {
    error("unsupported architecture must be amd64 or arm64")
  }

opsys := if os() == "macos" {
    "darwin"
  } else if os() == "linux" {
    "linux"
  } else {
    error("unsupported operating system must be darwin or linux")
  }

#------------
# cluster dev
#------------

cue_release := "v0.6.0" # or "v0.5.0", etc.
cue_binary_tarball_filename := "cue_" + cue_release + "_" + opsys + "_" + architecture + ".tar.gz"
cue_binary_url := "https://github.com/cue-lang/cue/releases/download/" + cue_release + "/" + cue_binary_tarball_filename

# Install cue (check/set: cue_release)
[unix]
install-cue:
  curl -L -o {{cue_binary_tarball_filename}} {{cue_binary_url}} && \
  tar -xzf {{cue_binary_tarball_filename}} && \
  sudo install -c -m 0755 cue /usr/local/bin && \
  rm -f cue
  which cue
  cue version

# Instal go dependencies
getgodeps:
  go get k8s.io/api/apps/v1
  cue get go k8s.io/api/apps/v1

# Generate yaml for kubernetes resources from cue configuration
cue:
  cue fmt
  cue vet
  cue cmd ls ./templates/...
  cue cmd dump ./templates/... > ./templates/resources.yaml

# Execute cue trim to remove redundant data
trim:
  cue trim ./templates/... -s

# Generate yaml for kubernetes resources from cue configuration with hof
hof:
  hof gen ./templates/**/*.cue -T =./templates/resources.yaml

skaffold_release := "latest" # or "v2.7.1" or "v2.6.4"

skaffold_binary_url := if skaffold_release == "latest" {
  "https://github.com/GoogleContainerTools/skaffold/releases/latest/download/skaffold-" + opsys + "-" + architecture
} else {
  "https://github.com/GoogleContainerTools/skaffold/releases/download/" + skaffold_release + "/skaffold-" + opsys + "-" + architecture
}

# Install skaffold (check/set: skaffold_release)
[unix]
install-skaffold:
  curl -L -o skaffold {{skaffold_binary_url}} && \
  sudo install -c -m 0755 skaffold /usr/local/bin && \
  rm -f skaffold
  which skaffold
  skaffold version

# Print skaffold info
info:
  skaffold version
  skaffold --help
  skaffold options
  skaffold config list
  skaffold diagnose

# Render skaffold yaml with latest container_image
render:
  skaffold render -t latest

# Build image with skaffold
build:
  skaffold build

# Deploy latest container_image in current kube context (invert: terminate)
deploy:
  skaffold deploy -t latest

# Stop latest container_image in current kube context (invert: start)
stop:
  kubectl scale deployment/{{git_repo_name}} --replicas=0 -n {{git_repo_name}}

# Start latest container_image in current kube context (invert: stop)
start:
  kubectl scale deployment/{{git_repo_name}} --replicas=1 -n {{git_repo_name}}

# Delete deployment for container_image in current kube context (invert: deploy)
terminate:
  kubectl delete -f cluster/resources/deployment.yaml

# Delete all resources created by skaffold
delete:
  skaffold delete

kaniko_service_account_email := "kaniko-" + git_repo_name + "@" + gcp_project_id + ".iam.gserviceaccount.com"

# Create kaniko service account and download key
get-kaniko-credentials:
  gcloud iam service-accounts describe {{kaniko_service_account_email}} || \
  gcloud iam service-accounts create kaniko-{{git_repo_name}} --display-name="kaniko {{git_repo_name}} service account" && \
  gcloud projects add-iam-policy-binding {{gcp_project_id}} \
    --member=serviceAccount:{{kaniko_service_account_email}} \
    --role=roles/artifactregistry.createOnPushWriter \
    --role=roles/artifactregistry.repositories.uploadArtifacts
  gcloud iam service-accounts keys create ./kaniko-key.json \
  --iam-account {{kaniko_service_account_email}}

# Create container regcred from docker-config.json to use with pullSecretName: regcred if private
create-regcred:
  kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=./docker-config.json \
  --type=kubernetes.io/dockerconfigjson \
  --dry-run=client -o yaml > ./regcred-secret.yaml

#---------------------
# container management
#---------------------

# Regenerate conda lock file.
lock:
  conda-lock \
  --conda mamba \
  --lockfile containers/conda-lock.yml \
  --virtual-package-spec containers/virtual-packages.yml \
  --log-level DEBUG \
  -f containers/environment.yml \
  -p linux-64

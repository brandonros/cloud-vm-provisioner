#!/usr/bin/env just --justfile

set shell := ["bash", "-euo", "pipefail", "-c"]
set export

script_path := justfile_directory()

default:
    @just --list

provision-vm:
  #!/usr/bin/env bash
  cd vms/hetzner
  terraform init
  terraform apply -auto-approve

fetch-kubeconfig server_ip='':
  #!/usr/bin/env bash

  # extract server_ip form tfstate
  server_ip="{{server_ip}}"
  if [[ -z "${server_ip}" ]]; then
    if terraform_output="$(cd vms/hetzner && terraform output -raw server_ipv4 2>/dev/null)"; then
      server_ip="${terraform_output}"
    else
      echo "error: server IPv4 not provided; pass it as an argument or export SERVER_IP" >&2
      exit 1
    fi
  fi
  if [[ -z "${server_ip}" ]]; then
    echo "error: server IPv4 is empty" >&2
    exit 1
  fi

  # wait for host to be available
  while ! nc -z "${server_ip}" 22 >/dev/null 2>&1; do
    sleep 2
  done

  ssh_key_path="${SSH_KEY_PATH:-${SSH_PRIVATE_KEY_PATH:-${HOME}/.ssh/id_rsa}}"
  remote_user="${REMOTE_USER:-user}"

  # wait for k3s to be ready
  ssh -o StrictHostKeyChecking=no -i "${ssh_key_path}" "${remote_user}@${server_ip}" \
    'while [ ! -f /home/user/k3s.yaml ]; do sleep 2; done'

  # pull kubeconfig file
  repo_root="$(pwd)"
  kubeconfig_path="${KUBECONFIG_PATH:-${repo_root}/k3s.yaml}"
  ssh -o StrictHostKeyChecking=no -i "${ssh_key_path}" "${remote_user}@${server_ip}" \
    'cat /home/user/k3s.yaml' \
  | sed "s|https://127.0.0.1:6443|https://${server_ip}:6443|" > "${kubeconfig_path}"
  echo "Kubeconfig written to ${kubeconfig_path}"

cleanup:
  #!/bin/bash
  cd vms/hetzner
  terraform destroy

install-gateway-api kubeconfig='':
  #!/usr/bin/env bash

  repo_root="$(pwd)"
  kubeconfig="{{kubeconfig}}"
  if [[ ! "${kubeconfig}" = /* ]]; then
    kubeconfig="${repo_root}/${kubeconfig}"
  fi

  export KUBECONFIG="${kubeconfig}"

  # Check if the CRD exists and capture the return code without showing errors
  if ! kubectl get crd gatewayclasses.gateway.networking.k8s.io &>/dev/null; then
      echo "Gateway API CRD not found. Installing..."
      kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml
      kubectl wait --for condition=established --timeout=60s crd/gatewayclasses.gateway.networking.k8s.io
  fi

  echo "Gateway API setup complete."

deploy chart='' release='' namespace='' kubeconfig='' repo='' version='':
  #!/usr/bin/env bash

  repo_root="$(pwd)"
  kubeconfig="{{kubeconfig}}"
  if [[ ! "${kubeconfig}" = /* ]]; then
      kubeconfig="${repo_root}/${kubeconfig}"
  fi
  export KUBECONFIG="${kubeconfig}"

  chart="{{chart}}"
  chart_dir="${repo_root}/manifests/${chart}"
  
  release_name="{{release}}"
  if [[ -z "${release_name}" ]]; then
      release_name="${chart}"
  fi

  namespace_name="{{namespace}}"
  if [[ -z "${namespace_name}" ]]; then
      namespace_name="${release_name}"
  fi

  repo_url="{{repo}}"
  version="{{version}}"
  
  # Determine if we're using a remote repo or local chart
  if [[ -n "${repo_url}" ]]; then
      # Remote chart from repo
      repo_name=$(echo "${repo_url}" | sed 's|https://||; s|/.*||; s|\.|-|g')
      helm repo add "${repo_name}" "${repo_url}"
      helm repo update
      chart_ref="${repo_name}/${chart}"
      
      helm_args=(
          --namespace "${namespace_name}"
          --create-namespace
      )
      
      if [[ -n "${version}" ]]; then
          helm_args+=(--version "${version}")
      fi
      
      # Add values file if it exists
      if [[ -f "${chart_dir}/values.yaml" ]]; then
          helm_args+=(--values "${chart_dir}/values.yaml")
      fi
      
      helm upgrade --install "${release_name}" "${chart_ref}" "${helm_args[@]}"
  else
      # Local chart directory
      if [[ ! -d "${chart_dir}" ]]; then
          echo "error: chart directory ${chart_dir} not found" >&2
          exit 1
      fi
      
      helm dependency update "${chart_dir}"
      helm upgrade --install "${release_name}" "${chart_dir}" \
          --namespace "${namespace_name}" \
          --create-namespace
  fi
  
  echo "Chart ${chart} deployed as release ${release_name} in namespace ${namespace_name} using kubeconfig ${kubeconfig}"

go:
  just provision-vm
  just fetch-kubeconfig
  just install-gateway-api k3s.yaml
  just deploy cert-manager cert-manager cert-manager k3s.yaml https://charts.jetstack.io v1.15.3
  just deploy traefik traefik traefik k3s.yaml https://traefik.github.io/charts 34.4.0
  just deploy metrics-server metrics-server kube-system k3s.yaml https://kubernetes-sigs.github.io/metrics-server/ 3.12.2
  just deploy nginx nginx nginx k3s.yaml
  just deploy routing routing kube-system k3s.yaml

#!/bin/sh

set -e

interval=$1
checks=$2
deployment_id=$3
kubectl_version=$4
installed_kubectl_version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

echo $interval
echo $checks
echo $deployment_id
echo $kubectl_version

if [ -n "$kubectl_version" ]; then
  if [ $kubectl_version != $installed_kubectl_version ]; then
    echo "Installing kubectl $kubectl_version"
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/linux/amd64/kubectl
    chmod +x ./kubectl && mv ./kubectl /usr/bin/kubectl
  fi
fi

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config
export KUBECONFIG=/tmp/config

finish()
{
  cat application_status.json | jq -r '.items | .[] | .logs'
  echo "::set-output name=kubectl-output::$STATUS"
}

i=0
while [ $i -lt $checks ]
do
  echo "checking status"
  sh -c "kubectl get applicationstatus -lfiaas/deployment_id=$deployment_id -ojson > application_status.json"
  STATUS=$(cat application_status.json | jq -r '.items | .[] | .result')
  if [ "SUCCESS" = "$STATUS" ]; then
    echo "Application deployed successfully"
    finish
    return 0
  fi
  if [ "FAILED" = "$STATUS" ]; then
    echo "Failed to deploy application"
    finish
    return 1
  fi
  i=$((i+1))
  echo "Application deployment still in status RUNNING, trying again in ${$interval}s"
  sleep $interval
done
echo "Application status check timed out"
finish
return 0

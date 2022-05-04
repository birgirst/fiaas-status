#!/bin/sh

set -e

interval=$1
checks=$2
deployment_id=$3
kubectl_version=$4

echo $interval
echo $checks
echo $deployment_id
echo $kubectl_version

curl -LO https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl
chmod +x ./kubectl && \
    mv ./kubectl /usr/bin/kubectl 

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config
export KUBECONFIG=/tmp/config
i=0
while [ $i -lt $checks ]
do
  echo "checking status"
  STATUS=$(sh -c "kubectl get applicationstatus -lfiaas/deployment_id=$deployment_id -ojson | jq '.items | .[] | .result' | sed 's/\\\"//g'")
  if [ "SUCCESS" = "$STATUS" ]; then
    echo "success"
    echo "::set-output name=kubectl-output::$STATUS"
    return 0
  fi
  i=$((i+1))
  sleep $interval
done
echo "::set-output name=kubectl-output::$STATUS"
return 1

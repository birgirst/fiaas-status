#!/bin/sh

set -e

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 -d > /tmp/config
export KUBECONFIG=/tmp/config
i=0
while [ $i -lt 5 ]
do
  echo "checking status"
  STATUS=$(sh -c "kubectl get applicationstatus -lfiaas/deployment_id=$* -ojson | jq '.items | .[] | .result' | sed 's/\\\"//g'")
  if [ "SUCCESS" = "$STATUS" ]; then
    echo "success"
    echo "::set-output name=kubectl-output::$STATUS"
    return 0
  fi
  ((i++))
  sleep 30
done
echo "::set-output name=kubectl-output::$STATUS"
return 1

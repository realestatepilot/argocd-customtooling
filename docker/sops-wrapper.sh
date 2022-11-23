#!/bin/bash
# paste VAULT_TOKEN in environment
# script is called becauese variable HELM_SECRETS_SOPS_PATH is set
echo "run sops-wrapper" >> /tmp/sops-wrapper.log

if [ -n $VAULT_ADDR ] 
then
  export VAULT_TOKEN=$(cat /tmp/.vault_token)
fi

printenv | grep "VAULT" >> /proc/1/fd/1 2>&1 &
printenv | grep "VAULT" >> /tmp/sops-wrapper.log

sops $@
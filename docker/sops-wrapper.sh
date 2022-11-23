#/bin/bash
# paste VAULT_TOKEN in environment
# script is called becauese variable HELM_SECRETS_SOPS_PATH is set
source ~/.bashrc

printenv >> /proc/1/fd/1 2>&1 &

sops $@
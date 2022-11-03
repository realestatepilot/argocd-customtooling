#!/bin/bash

# adapt this to your existing vault
VAULT_ADDR=https://vault.organization.tld

cd ..
ls -al
VERSION=$(< version.txt)
echo $VERSION
docker build --build-arg argocd_version=$VERSION -t realestatepilot/argocd-customtooling:$VERSION-dev .

cd tests

docker run --name repo --rm -it \
  -e VAULT_ADDR=$VAULT_ADDR \
  -v $PWD/roleid:/etc/vault.d/roleid \
  -v $PWD/secretid:/etc/vault.d/secretid \
  realestatepilot/argocd-customtooling:$VERSION-dev /usr/local/bin/entrypoint.sh argocd-repo-server

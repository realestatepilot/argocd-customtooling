# run local test 
# docker build --build-arg argocd_version=v2.5.0-rc3 -t realestatepilot/argocd-customtooling:v2.5.0-rc3-dev2 .
# docker run --name repo --rm -it -e VAULT_ADDR=https://vault.organization.org -v $PWD/roleid:/etc/vault.d/roleid -v $PWD/secretid:/etc/vault.d/secretid realestatepilot/argocd-customtooling:v2.5.0-rc3-dev2 /usr/local/bin/entrypoint.sh argocd-repo-server

# argocd version is triggered from https://github.com/argoproj/argo-cd/releases
ARG argocd_version=undef
FROM argoproj/argocd:$argocd_version

# this versions are set manually
ENV SOPS_VERSION=v3.7.3
ENV HELM_SECRETS_VERSION=v4.1.1

# In case wrapper scripts are used, HELM_SECRETS_HELM_PATH needs to be the path of the real helm binary
ENV HELM_SECRETS_HELM_PATH=/usr/local/bin/helm \
    HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/" \
    HELM_SECRETS_VALUES_ALLOW_SYMLINKS=false \
    HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH=false \
    HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL=false

# Switch to root for the ability to perform install
USER root

RUN apt-get update && \
    apt-get install -y wget gpg

# from hashicorp install docu, but 
# * wget line `>` instead of `| tee` to keep console free from binary clutter
# * `lsb_relase -cs`substituted with `echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f2) main" | tee /etc/apt/sources.list.d/hashicorp.list`

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(cat /etc/os-release | grep VERSION_CODENAME | cut -d "=" -f2) main" | tee /etc/apt/sources.list.d/hashicorp.list

# # Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests 
RUN apt-get update && \
    apt-get install -y \
        curl \
        vault \
        gpg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux && \
    chmod +x /usr/local/bin/sops

COPY docker/vault.hcl /etc/vault.d/vault.hcl

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh 
RUN chmod 755 /usr/local/bin/entrypoint.sh 

# use start script for vault which is also check regulary if restart vault agent is needed
COPY docker/vault-restart.sh /home/argocd/vault-restart.sh
RUN chmod 777 /home/argocd/vault-restart.sh

# # Switch back to non-root user
USER 999
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version $HELM_SECRETS_VERSION

# install vault agent config and startup routine for them
COPY docker/.bashrc /home/argocd/.bashrc

# run test 
# docker build --build-arg argocd_version=v2.5.0-rc3 -t test .

# argocd version is triggered from https://github.com/argoproj/argo-cd/releases
ARG argocd_version=undefined
FROM argoproj/argocd:$argocd_version

# this versions are set manually
ENV sops_version=v3.7.3
ENV helm_secrets_version=v4.1.1

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
RUN curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux && \
    chmod +x /usr/local/bin/sops

# # Switch back to non-root user
USER 999

RUN export HELM_CACHE_HOME=/helm-working-dir && \
    export HELM_CONFIG_HOME=/helm-working-dir && \
    export HELM_DATA_HOME=/helm-working-dir
    
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version $helm_secrets_version


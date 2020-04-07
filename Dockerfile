FROM centos:7
ENV AKS_VERSION v0.44.2
ENV HELM_VERSION v2.16.1
RUN /bin/sh -c 'rpm --import https://packages.microsoft.com/keys/microsoft.asc'
RUN /bin/sh -c 'cd /etc/yum.repos.d'
RUN /bin/sh -c 'touch azure-cli.repo'
RUN /bin/sh -c 'echo -e "[azure-cli] \n\
name=Azure CLI \n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli  \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
RUN /bin/sh -c 'yum -y install git libffi-devel.x86_64 gcc openssl-devel bzip2-devel make'
RUN /bin/sh -c 'curl https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz --output /tmp/Python-3.7.0.tgz'
RUN /bin/sh -c 'cd /tmp && tar -xvpzf Python-3.7.0.tgz && cd /tmp/Python-3.7.0 && ./configure --enable-optimizations && make altinstall'
RUN /bin/sh -c 'rm -rf /tmp/Python*'
#RUN /bin/sh -c 'rm /usr/bin/python && ln -s  /usr/local/bin/python3.7 /usr/bin/python'
RUN /bin/sh -c 'yum -y install azure-cli gcc'
RUN /bin/sh -c 'mkdir /Prod && cd /Prod'
ADD requirements /tmp
RUN /bin/sh -c 'python3.7 -m venv /Prod'
RUN  /bin/sh -c  '. /Prod/bin/activate && pip3.7 install -r /tmp/requirements'
ADD https://github.com/Azure/aks-engine/releases/download/${AKS_VERSION}/aks-engine-${AKS_VERSION}-linux-amd64.tar.gz /Prod
RUN /bin/sh -c 'cd /Prod && tar -xvpzf aks-engine-${AKS_VERSION}-linux-amd64.tar.gz'
RUN /bin/sh -c 'ln -s /Prod/aks-engine-${AKS_VERSION}-linux-amd64/aks-engine /usr/local/bin/aks-engine'
ADD https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz /Prod
RUN /bin/sh -c 'mkdir -p /Prod/helm && tar -C /Prod/helm/ -xvpzf /Prod/helm-${HELM_VERSION}-linux-amd64.tar.gz'
RUN /bin/sh -c 'ln -s /Prod/helm/linux-amd64/helm /usr/local/bin/helm'
RUN /bin/sh -c 'ln -s /Prod/helm/linux-amd64/tiller /usr/local/bin/tiller'
#Patch the modules for subnet creation so they work with IPv6
RUN /bin/sh -c 'sed -i -e "s/if self.address_prefix_cidr and not /#if self.address_prefix_cidr and not /g"  /Prod/lib/python3.7/site-packages/ansible/modules/cloud/azure/azure_rm_subnet.py'
RUN /bin/sh -c 'sed -i -e "s/self.fail(\"Invalid address_prefix_cidr/#self.fail(\"Invalid address_prefix_cidr/g"  /Prod/lib/python3.7/site-packages/ansible/modules/cloud/azure/azure_rm_subnet.py'
RUN  /bin/sh -c  '. /Prod/bin/activate'

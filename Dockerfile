FROM quay.io/openshifthomeroom/workshop-dashboard:5.0.0

ENV COCKROACH_VERSION=cockroach-v22.2.7.linux-amd64

USER root

COPY . /tmp/src

RUN rm -rf /tmp/src/.git* && \
    chown -R 1001 /tmp/src && \
    chgrp -R 0 /tmp/src && \
    chmod -R g+w /tmp/src

RUN cd /opt/app-root/bin && \
    wget https://binaries.cockroachdb.com/${COCKROACH_VERSION}.tgz && \
    tar -xzvf ${COCKROACH_VERSION}.tgz && \
    mv ${COCKROACH_VERSION}/cockroach . && \
    mkdir -p /usr/local/lib/cockroach && \
    mv ${COCKROACH_VERSION}/lib/* /usr/local/lib/cockroach/ && \
    yum -y install https://github.com/tektoncd/cli/releases/download/v0.30.1/tektoncd-cli-0.30.1_Linux-64bit.rpm && \
    yum clean all

USER 1001

RUN /usr/libexec/s2i/assemble

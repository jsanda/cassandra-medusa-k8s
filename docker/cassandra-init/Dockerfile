FROM bitnami/minideb:stretch

ENV \
    CASSANDRA_HOME=/opt/cassandra \
    CASSANDRA_DATA=/var/lib/cassandra \
    CASSANDRA_CONF=/etc/cassandra \
    BOOTSTRAP_LIB=/bootstrap/lib \
    JOLOKIA_VERSION=1.6.2

RUN mkdir -p $CASSANDRA_DATA $CASSANDRA_CONF $BOOTSTRAP_LIB && \
    apt-get update && \
    apt-get -qq -y install --no-install-recommends ca-certificates wget netcat iproute2 && \
    wget -O ${BOOTSTRAP_LIB}/jolokia-agent.jar http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar && \
    groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra && \
    chown -R cassandra:cassandra $CASSANDRA_DATA $CASSANDRA_CONF $BOOTSTRAP_LIB && \
    apt-get -y purge && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf doc \
              man \
              info \
              locale \
              common-licenses \
              ~/.bashrc \
              /var/lib/apt/lists/* \
              /var/log/**/* \
              /var/cache/debconf/* \
              /etc/systemd \
              /lib/lsb \
              /lib/udev \
              /usr/share/doc/ \
              /usr/share/doc-base/ \
              /usr/share/man/ \
              /tmp/* && \
    mkdir -p $CASSANDRA_HOME && \
    ln -s "$CASSANDRA_CONF" "$CASSANDRA_HOME/conf"

USER cassandra

COPY conf/ /tmp

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

#!/bin/bash
set -e

CASSANDRA_CONF=/etc/cassandra

cp /tmp/cassandra.yaml /etc/cassandra
cp /tmp/cassandra-env.sh /etc/cassandra
cp /tmp/jvm.options /etc/cassandra
cp /tmp/cassandra-rackdc.properties /etc/cassandra
cp /tmp/logback.xml /etc/cassandra
cp $BOOTSTRAP_LIB/jolokia-agent.jar /etc/cassandra

# https://issues.apache.org/jira/browse/CASSANDRA-13345
# "The stack size specified is too small, Specify at least 328k"
if grep -q -- '^-Xss' "$CASSANDRA_CONF/jvm.options"; then
    # 3.11+ (jvm.options)
    grep -- '^-Xss256k$' "$CASSANDRA_CONF/jvm.options";
    sed -ri 's/^-Xss256k$/-Xss512k/' "$CASSANDRA_CONF/jvm.options"
    grep -- '^-Xss512k$' "$CASSANDRA_CONF/jvm.options"
elif grep -q -- '-Xss256k' "$CASSANDRA_CONF/cassandra-env.sh"; then
    # 3.0 (cassandra-env.sh)
    sed -ri 's/-Xss256k/-Xss512k/g' "$CASSANDRA_CONF/cassandra-env.sh"
    grep -- '-Xss512k' "$CASSANDRA_CONF/cassandra-env.sh"
fi

_ip_address() {
        # scrape the first non-localhost IP address of the container
        # in Swarm Mode, we often get two IPs -- the container IP, and the (shared) VIP, and the container IP should always be first
        ip address | awk '
                $1 == "inet" && $NF != "lo" {
                        gsub(/\/.+$/, "", $2)
                        print $2
                        exit
                }
        '
}

# "sed -i", but without "mv" (which doesn't work on a bind-mounted file, for example)
_sed-in-place() {
        local filename="$1"; shift
        local tempFile
        tempFile="$(mktemp)"
        sed "$@" "$filename" > "$tempFile"
        cat "$tempFile" > "$filename"
        rm "$tempFile"
}

: ${CASSANDRA_RPC_ADDRESS='0.0.0.0'}

: ${CASSANDRA_LISTEN_ADDRESS='auto'}
if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
    CASSANDRA_LISTEN_ADDRESS="$(_ip_address)"
fi

: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
    CASSANDRA_BROADCAST_ADDRESS="$(_ip_address)"
fi
: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

if [ -n "${CASSANDRA_NAME:+1}" ]; then
    : ${CASSANDRA_SEEDS:="cassandra"}
fi
: ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}

_sed-in-place "$CASSANDRA_CONF/cassandra.yaml" \
    -r 's/(- seeds:).*/\1 "'"$CASSANDRA_SEEDS"'"/'

for yaml in \
        broadcast_address \
        broadcast_rpc_address \
        cluster_name \
        endpoint_snitch \
        listen_address \
        num_tokens \
        rpc_address \
        start_rpc \
; do
    var="CASSANDRA_${yaml^^}"
    val="${!var}"
    if [ "$val" ]; then
        _sed-in-place "$CASSANDRA_CONF/cassandra.yaml" \
            -r 's/^(# )?('"$yaml"':).*/\2 '"$val"'/'
    fi
done

for rackdc in dc rack; do
     var="CASSANDRA_${rackdc^^}"
     val="${!var}"
     if [ "$val" ]; then
         _sed-in-place "$CASSANDRA_CONF/cassandra-rackdc.properties" \
             -r 's/^('"$rackdc"'=).*/\1 '"$val"'/'
     fi
done

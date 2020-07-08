#!/bin/bash
set -e

# first arg is `-f` or `--some-option`
# or there are no args
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
	set -- cassandra -f "$@"
fi

rm -rf $CASSANDRA_HOME/conf
ln -sT "$CASSANDRA_CONF" "$CASSANDRA_HOME/conf";

echo "sleeping for $DEBUG_SLEEP sec"
sleep $DEBUG_SLEEP


echo $@
exec "$@"

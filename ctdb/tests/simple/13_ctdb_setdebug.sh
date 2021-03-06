#!/bin/bash

test_info()
{
    cat <<EOF
Verify that 'ctdb setdebug' works as expected.

This is a little superficial.  It checks that CTDB thinks the debug
level has been changed but doesn't actually check that logging occurs
at the new level.
EOF
}

. "${TEST_SCRIPTS_DIR}/integration.bash"

ctdb_test_init "$@"

set -e

cluster_is_healthy

select_test_node_and_ips

get_debug ()
{
    # Sets: check_debug
    local node="$1"

    local out
    
    try_command_on_node -v $node "$CTDB getdebug"
    check_debug=$(echo "$out" |
	sed -r -e 's@Node [[:digit:]]+ is at debug level ([[:alpha:]]+) \(-?[[:digit:]]+\)$@\1@')
}

set_and_check_debug ()
{
    local node="$1"
    local level="$2"

    echo "Setting debug level on node ${node} to ${level}."
    try_command_on_node $node "$CTDB setdebug ${level}"

    local check_debug
    get_debug $node

    if [ "$level" != "$check_debug" ] ; then
	echo "BAD: Debug level should have changed to \"$level\" but it is \"$check_debug\"."
	testfailures=1
    fi
}

get_debug $test_node
initial_debug="$check_debug"

levels="ERR WARNING NOTICE INFO DEBUG"

for new_debug in $levels ; do
    [ "$initial_debug" != "$new_debug" ] || continue

    echo
    set_and_check_debug $test_node "$new_debug"
done

if [ "$testfailures" != 1 ] ; then
    echo
    echo "Returning the debug level to its initial value..."
    set_and_check_debug $test_node "$initial_debug"
fi

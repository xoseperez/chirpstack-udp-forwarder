#!/usr/bin/env bash

# Checks a built image before it is pushed: the binary runs on the platform, the
# start script renders a complete configuration from environment variables, and
# the forwarder accepts that configuration.
#
#   docker/smoke-test.sh IMAGE PLATFORM

set -euo pipefail

IMAGE=$1
PLATFORM=$2

# --init keeps the tested command from becoming PID 1, which signals sent from
# inside the container (such as the timeout below) cannot kill.
run() { docker run --rm --init --platform "${PLATFORM}" --network none "$@"; }

echo "== ${PLATFORM}: binary"
run "${IMAGE}" ./chirpstack-udp-forwarder -V

echo "== ${PLATFORM}: configuration"
CONFIG=$(run -e SERVER_HOST=lns.example.com -e SERVER_PORT=1701 -e KEEPALIVE_INTERVAL=15 \
    "${IMAGE}" bash start --render)
echo "${CONFIG}"
if grep -nE '\$\{|\{\{' <<< "${CONFIG}"; then
    echo "FAIL: placeholders left in the configuration" >&2
    exit 1
fi
for expected in 'server="lns.example.com:1701"' 'keepalive_interval_secs=15'; do
    if ! grep -qF "${expected}" <<< "${CONFIG}"; then
        echo "FAIL: '${expected}' missing from the configuration" >&2
        exit 1
    fi
done

echo "== ${PLATFORM}: forwarder accepts the configuration"
# With no concentratord to talk to, the forwarder gives up, or is killed by the
# timeout, after reading its configuration and logging that it started. Under
# emulation it can get stuck waiting for concentratord without reacting to
# SIGTERM, so the timeout sends SIGKILL.
OUTPUT=$(run -e SERVER_HOST=127.0.0.1 "${IMAGE}" \
    bash -c 'bash start --render > /dev/null && timeout -s KILL 10 ./chirpstack-udp-forwarder -c run/config.toml' 2>&1 || true)
echo "${OUTPUT}"
if ! grep -q 'Starting ChirpStack UDP Forwarder' <<< "${OUTPUT}"; then
    echo "FAIL: the forwarder did not get past reading its configuration" >&2
    exit 1
fi

echo "== ${PLATFORM}: OK"

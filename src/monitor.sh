#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
umask 027
set -o noclobber

ENDPOINT="${ENDPOINT:-http://example.com/login}"
cliente_curl(){
    resultado=$(curl --write-out "%{http_code} %{time_total}" "$ENDPOINT" -o /dev/null)
    http_code=$(echo "$resultado" | awk '{print $1}')
    time_total=$(echo "$resultado" | awk '{print $2}')
    echo "endpoint : $ENDPOINT"
    echo "http_code : $http_code"
    echo "time_total : $time_total"
}
cliente_curl
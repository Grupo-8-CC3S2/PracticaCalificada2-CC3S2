#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
umask 027
set -o noclobber

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_csv.sh"

ENDPOINT="${ENDPOINT:-http://facebook.com/login}"

cliente_curl(){
    resultado=$(curl --write-out "%{http_code} %{time_total}" "$ENDPOINT" -o /dev/null)
    http_code=$(echo "$resultado" | awk '{print $1}')
    time_total=$(echo "$resultado" | awk '{print $2}')
    echo "endpoint : $ENDPOINT"
    echo "http_code : $http_code"
    echo "time_total : $time_total"

    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    ms=$(awk -v tt="$time_total" 'BEGIN{printf("%.0f", tt*1000)}')
    csv_append "$ts" "$ENDPOINT" "$http_code" "$ms"
}
cliente_curl
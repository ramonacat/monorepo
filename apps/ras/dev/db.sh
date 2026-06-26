#!/usr/bin/env bash
set -euo pipefail

PGDATA="$(pwd)/.postgres_data/"

export PGDATA

start() {
	stop || true

	rm -r "$PGDATA" || true
	mkdir -p "$PGDATA"

	initdb --pgdata "$PGDATA" --no-data-checksums --no-sync --no-sync-data-files
	echo "unix_socket_directories='$(pwd)'" >>"$PGDATA/postgresql.conf"
	pg_ctl -D "$PGDATA" -l postgres.log start
	psql --dbname postgres --host="$(pwd)" -c "CREATE ROLE ras WITH LOGIN PASSWORD 'ras'"
	psql --dbname postgres --host="$(pwd)" -c 'CREATE DATABASE ras OWNER ras'
}

stop() {
	pg_ctl -D "$PGDATA" stop
}

if [[ $# != 1 ]]; then
	echo "provide a command (start or stop)"
	exit 1
fi

case "$1" in
"start")
	start
	;;
"stop")
	stop
	;;
*)
	echo "unknown command: $1"
	exit 1
	;;
esac

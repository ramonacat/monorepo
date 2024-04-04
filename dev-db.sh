#!/usr/bin/env bash

DATABASE_PATH=.tmp/raddb

function start_db() {
    pg_ctl -D "$DATABASE_PATH" -l .tmp/raddb.log -o "--unix-socket-directories='$PWD'" start
}

case $1 in
    start)
        if [[ -d "$DATABASE_PATH" ]]; then
            start_db
        else
            mkdir -p "$DATABASE_PATH"
            initdb -D "$DATABASE_PATH"

            start_db

            createdb -h "$PWD" rad
        fi
        ;;
    stop)
        pg_ctl -D "$DATABASE_PATH" -l .tmp/raddb.log -o "--unix-socket-directories='$PWD'" stop
        ;;
esac


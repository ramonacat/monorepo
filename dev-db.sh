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
            createdb -h "$PWD" ras
        fi
        ;;
    stop)
        pg_ctl -D "$DATABASE_PATH" -l .tmp/raddb.log -o "--unix-socket-directories='$PWD'" stop
        ;;
    context)
        case $2 in
            ras)
                DBNAME=ras
                ;;
            rad)
                DBNAME=rad
                ;;
            *)
                >&2 echo "Invalid DB name $2"
                exit 1;
                ;;
        esac
        echo "DATABASE_URL = \"postgres://ramona:@localhost/$DBNAME\";";
        ;;
esac


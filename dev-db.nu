#!/usr/bin/env nu

const database_path = '.tmp/raddb'

def do_pg_ctl [...$args: string] {
    pg_ctl -D $database_path -l .tmp/raddb.log -o $"--unix-socket-directories='($env.PWD)'" ...$args
}

def "main start" [] {
    if ($database_path | path exists) {
        do_pg_ctl start
    } else {
        mkdir $database_path
        initdb -D $database_path

        do_pg_ctl start

        createdb -h $env.PWD rad
        createdb -h $env.PWD ras
    }
}

def "main stop" [] {
    do_pg_ctl stop
}

def "main context" [db_name: string] {
    if $db_name not-in ['rad', 'ras'] {
        print ('Unknown database ' + $db_name)
        exit 1
    }
    {'DATABASE_URL': ('postgres://ramona:@localhost/' + $db_name)} | to json
}

def main [] {
    echo 'Unknown command'
}

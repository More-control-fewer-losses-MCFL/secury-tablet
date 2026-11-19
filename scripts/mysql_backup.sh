#!/bin/sh
# Run inside the MySQL image. Dumps InnoDB consistently; restores only to an
# existing, empty database whose name ends in _test.
set -eu
umask 077

: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
MYSQL_HOST=${MYSQL_HOST:-127.0.0.1}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_PWD=$MYSQL_PASSWORD
export MYSQL_PWD

case "${1:-}" in
    backup)
        [ "$#" -eq 2 ] || { echo 'Usage: secury-mysql-backup backup OUTPUT.sql' >&2; exit 2; }
        output=$2
        [ ! -e "$output" ] || { echo 'Backup destination already exists' >&2; exit 2; }
        temporary="${output}.partial.$$"
        trap 'rm -f "$temporary"' EXIT HUP INT TERM
        mysqldump \
            --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" \
            --single-transaction --quick --routines --triggers --events \
            --set-gtid-purged=OFF --no-tablespaces --default-character-set=utf8mb4 \
            --result-file="$temporary" "$MYSQL_DATABASE"
        [ -s "$temporary" ] || { echo 'Backup is empty' >&2; exit 1; }
        mv "$temporary" "$output"
        trap - EXIT HUP INT TERM
        echo "Backup written to $output"
        ;;
    restore-test)
        [ "$#" -eq 3 ] || {
            echo 'Usage: secury-mysql-backup restore-test INPUT.sql EMPTY_DATABASE_test' >&2
            exit 2
        }
        input=$2
        target=$3
        printf '%s' "$target" | grep -Eq '^[A-Za-z0-9_]+_test$' || {
            echo 'Restore target must end in _test' >&2; exit 2;
        }
        [ "$target" != "$MYSQL_DATABASE" ] || { echo 'Restore target is source database' >&2; exit 2; }
        [ -s "$input" ] || { echo 'Backup file is missing or empty' >&2; exit 2; }
        existing=$(mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" \
            --database="$target" --batch --skip-column-names -e 'SHOW TABLES')
        [ -z "$existing" ] || { echo 'Restore target must be empty' >&2; exit 2; }
        mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" \
            --database="$target" < "$input"
        echo "Backup restored to isolated database $target"
        ;;
    *)
        echo 'Usage: secury-mysql-backup {backup OUTPUT.sql|restore-test INPUT.sql EMPTY_DATABASE_test}' >&2
        exit 2
        ;;
esac

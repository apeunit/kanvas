#!/usr/bin/env bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"/store-api-server

PEPPERMINT_VERSION=ee538be4d156ffb456107587eb71f14671afb1c7
[ -z $PGPORT ] && export PGPORT=5432
[ -z $PGPASSWORD ] && export PGPASSWORD=dev_password
[ -z $PGUSER ] && export PGUSER=dev_user
[ -z $PGDATABASE ] && export PGDATABASE=dev_database
[ -z $PGHOST ] && export PGHOST=localhost

(
    ./script/migrate.bash || exit 1

    psql < script/populate-testdb.sql
) &

[ -z $DOCKER_ARGS ] && export DOCKER_ARGS='-t'

docker run ${DOCKER_ARGS} \
    -p $PGPORT:5432 \
    -e POSTGRES_PASSWORD=$PGPASSWORD \
    -e POSTGRES_USER=$PGUSER \
    -e POSTGRES_DB=$PGDATABASE \
    postgres \
        -c wal_level=logical \
        "$@" 2>&1 >/dev/null

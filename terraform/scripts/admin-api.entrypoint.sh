 set -e -x
        ./script/wait-db
        INIT_QUEPASA=false ./script/migrate
        if [[ "`psql -c \"select count(1) from kanvas_user\" -tA`" == "0" ]]; then
          yarn seed
          ./script/setup-replication-sub
        fi
        if [ "${ADMIN_API_ENABLED:-yes}" == "yes" ]; then
          yarn run start:prod
        fi
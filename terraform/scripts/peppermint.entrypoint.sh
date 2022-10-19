 set -e -x
        while ! psql -d "$DATABASE_URL" -c "select 1 from peppermint.operations" ; do
          sleep 1
        done

        cp /config/peppermint.json config.json
        node app.mjs
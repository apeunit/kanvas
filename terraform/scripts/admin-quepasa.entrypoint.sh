set -e
        while ! psql -d "$DATABASE_URL" -c "select 1" ; do
          sleep 1
        done
        /que-pasa/que-pasa --bcd-enable
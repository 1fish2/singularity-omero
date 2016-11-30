#!/usr/bin/env bash

while ! pg_isready -h localhost -p $PG_PORT -d omero -U omero --quiet; do
  echo "Waiting for database to be up."
  sleep 5s
done

omero config set omero.db.host localhost
omero config set omero.db.port $PG_PORT
omero config set omero.db.name omero
omero config set omero.db.user omero
omero config set omero.db.pass $PGPASSWORD

omero config set omero.data.dir /omero/data
omero config set omero.ports.registry $REGISTRY_PORT
omero config set omero.ports.tcp $TCP_PORT
omero config set omero.ports.ssl $SSL_PORT

# Daily task to clean up sessions
# https://www.openmicroscopy.org/site/support/omero5.2/sysadmins/unix/install-web.html#omero-web-maintenance-unix-linux
omero web clearsessions

exec omero admin start --foreground

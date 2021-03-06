#!/usr/bin/env bash

export PGDATA=/omero/postgres

if [ ! -f $PGDATA/PG_VERSION ]; then
	echo "Initializing database..."

	initdb --locale en_US.utf8

	# Launch Postgres in a way that doesn't accept any connections unless the socket is known.
	# This prevents OMERO.server from connecting to the database before it's fully setup.
	# http://stackoverflow.com/a/28262109
	SOCKET=/tmp/pg_socket
	mkdir -p $SOCKET
	export PGHOST=$SOCKET
	pg_ctl -o "-c listen_addresses='' -c unix_socket_directories='$SOCKET'" -w start

	psql --username $USER -d postgres <<-EOSQL
		CREATE USER omero WITH SUPERUSER PASSWORD '$PGPASSWORD';
	EOSQL
	createdb -O omero omero

	INIT_FILE=/tmp/omero.sql
	omero db script -f $INIT_FILE --password password
	psql -U omero -d omero -f $INIT_FILE
	rm $INIT_FILE

	pg_ctl -m fast -w stop
	unset PGHOST

	# On active config lines (lines not commented out), replace 'trust' with 'md5'.
	# This requires passwords to be used when connecting to the database. If a
	# database user does not have a password, they will not be able to connect.
	sed -i.bak -E 's/^([^#].*)trust$/\1md5/' $PGDATA/pg_hba.conf
fi

exec postgres -p $PG_PORT

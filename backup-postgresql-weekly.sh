#! /bin/bash

# backup-postgresql.sh
# this script is public domain.  feel free to use or modify as you like.

# This script must be run as postgres user

DUMPALL="/usr/bin/pg_dumpall"
PGDUMP="/usr/bin/pg_dump"
PSQL="/usr/bin/psql"

# directory to save backups in, must be rwx by postgres user
BASE_DIR="/opt/backups-postgres/weeks"
YMD=$(date "+%Y-%m-%d")
DIR="$BASE_DIR/$YMD"
mkdir -p $DIR
cd $DIR

# get list of databases in system , exclude the tempate dbs
DBS=$($PSQL -l | awk '{ print $1}' | grep -vE '*_test|^-|^List|^Name|template[0|1]|^\||^\(')

# first dump entire postgres database, including pg_shadow etc.
$DUMPALL  | gzip -9 > "$DIR/db.out.gz"

# next dump globals (roles and tablespaces) only
$DUMPALL -g | gzip -9 > "$DIR/globals.gz"

# now loop through each individual database and backup the schema and data separately
for database in $DBS; do
    SCHEMA=$DIR/$database.schema.gz
    DATA=$DIR/$database.data.gz

    # export data from postgres databases to plain text
    $PGDUMP -C -s $database | gzip -9 > $SCHEMA

    # dump data
    $PGDUMP -a $database | gzip -9 > $DATA
done


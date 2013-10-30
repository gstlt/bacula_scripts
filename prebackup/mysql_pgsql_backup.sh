#!/bin/bash
#
# MySQL and PGSQL db backup script
# Tested also on MariaDB 5.5 up and should be working fine
# Pre backup script tested with Bacula and Duply
#
# TODO:
# - Checking return values for mysqldump and pg_dump to catch backup errors
# - Bzip2 backups

# Configuration
PGDUMPDIR=/opt/backups/pgsql
MYSQLDIR=/opt/backups/mysql

# MySQL password file
MYSQLPASS=/root/.my.cnf

# .my.cnf sample content:
# [client]
# user=root
# password=XXXXXXXXXXXXXXXXXXXXXX
# protocol=tcp

# Remove old backups
rm -f $PGDUMPDIR/*.schema.dump
rm -f $MYSQLDIR/*.mysql

# Backup MySQL
mysql --defaults-extra-file=$MYSQLPASS -B -N -e "show databases" | while read db
do
   BACKUPFILE=$MYSQLDIR/$db.mysql
   echo "Backing up $db into $BACKUPFILE"
   
   # backing up information_schema and performance_schema is not required and may lead to errors
   # see:
   # information_schema: http://bugs.mysql.com/bug.php?id=21527
   # performance_schema: 
   if [ "$db" == "information_schema" ] || [ "$db" == "performance_schema"  ]; then

      /usr/bin/mysqldump --defaults-extra-file=$MYSQLPASS --single-transaction --databases $db > $BACKUPFILE
      # or comment above line and uncomment below
      # echo "Skipping $db"

   else

      /usr/bin/mysqldump --defaults-extra-file=$MYSQLPASS --databases $db > $BACKUPFILE

   fi

done

# Backup PostgreSQL
for dbname in `psql -U postgres -d template1 -q -t <<EOF
select datname from pg_database where not datname in ('bacula','template0') order by datname;
EOF
` 
do
 # backup db schema
 echo "Backing up PGSQL DB: $dbname schema into $PGDUMPDIR/$dbname.schema.dump"
 su - postgres -c "/usr/bin/pg_dump -U postgres -s $dbname --file=$PGDUMPDIR/$dbname.schema.dump"
 # backup db data
 echo "Backing up PGSQL DB: $dbname data into $PGDUMPDIR/$dbname.data.dump"
 su - postgres -c "/usr/bin/pg_dump -U postgres -a $dbname --file=$PGDUMPDIR/$dbname.data.dump"

done

# needed for bacula-fd to recognise that pre backup script finished successfully
exit 0


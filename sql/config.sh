#!/bin/sh
echo "Enabling query logging"
perl -pi -e "s/#log_statement = 'none'/log_statement = 'all'/g" /var/lib/postgresql/data/postgresql.conf
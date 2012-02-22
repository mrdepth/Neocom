#!/bin/sh
rm *.sqlite
cd dump
datadump.py
cd ..
sqlite3 database.sqlite ".read init.sql"
sqlite3 database.sqlite ".read eufe/fixes.sql"
./compiler database.sqlite ./
sqlite3 ./database.sqlite ".read eufeInit.sql"
sqlite3 ./eufe.sqlite ".read dgmCompiledEffects.sql"

sqlite3 ./eveDB/eve.sqlite ".read init.sql"
sqlite3 ./eveDB/eve.sqlite ".read eveDB/evedbTablesExtract.sql" > tablesInit.sql
sqlite3 evedb.sqlite ".read tablesInit.sql"
sqlite3 ./eveDB/eve.sqlite ".read eveDbInit.sql"
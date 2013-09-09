#!/bin/sh
rm *.sqlite
cd dump
#./datadump.py
cd ..
sqlite3 database.sqlite ".read init.sql"
sqlite3 database.sqlite ".read eufe/fixes.sql"
./compiler database.sqlite ./

echo ".read eufeInit.sql"
sqlite3 ./database.sqlite ".read eufeInit.sql"

echo ".read dgmCompiledEffects.sql"
sqlite3 ./eufe.sqlite ".read dgmCompiledEffects.sql"
	
echo ".read init.sql"
sqlite3 ./eveDB/eve.sqlite ".read init.sql"

#sqlite3 ./eveDB/eve.sqlite ".read invMarketGroupsFix.sql"

echo ".read eveDB/evedbTablesExtract.sql"
sqlite3 ./eveDB/eve.sqlite ".read eveDB/evedbTablesExtract.sql" > tablesInit.sql

echo ".read tablesInit.sql"
sqlite3 evedb.sqlite ".read tablesInit.sql"

echo ".read eveDbInit.sql"
sqlite3 ./eveDB/eve.sqlite ".read eveDbInit.sql"

echo ".read eveDB/eveIcons.sql"
sqlite3 ./evedb.sqlite ".read eveDB/eveIcons.sql"
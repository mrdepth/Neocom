CC=clang++
CFLAGS=-arch x86_64 -std=gnu++11 -stdlib=libc++ -lsqlite3
T+=${PWD}/tmp
DUMP=${PWD}/input/dump
VPATH=${T}
SQL=${PWD}/sql
SDE+=${PWD}/input/sde/eve.sqlite

all: eufe.sqlite NCDatabase.sqlite

dbpatch: tmp
	$(CC) $(CFLAGS) ../dbpatch/dbpatch.cpp -o ./tmp/$@

EVEIconsConverter: tmp
	xcodebuild -project ../EVEIconsConverter/EVEIconsConverter.xcodeproj -configuration Release TARGET_BUILD_DIR=${T} OBJROOT=${T}/build SYMROOT=${T}/build

EVEIconsIDsParser: tmp
	xcodebuild -project ../EVEIconsIDsParser/EVEIconsIDsParser.xcodeproj -configuration Release TARGET_BUILD_DIR=${T} OBJROOT=${T}/build SYMROOT=${T}/build

EVETypesConverter: tmp
	xcodebuild -project ../EVETypesConverter/EVETypesConverter.xcodeproj -configuration Release TARGET_BUILD_DIR=${T} OBJROOT=${T}/build SYMROOT=${T}/build

EVENPCBuilder: tmp
	xcodebuild -project ../EVENPCBuilder/EVENPCBuilder.xcodeproj -configuration Release TARGET_BUILD_DIR=${T} OBJROOT=${T}/build SYMROOT=${T}/build

NCDatabase: tmp
	xcodebuild -project ../NCDatabase/NCDatabase.xcodeproj -configuration Release TARGET_BUILD_DIR=${T} OBJROOT=${T}/build SYMROOT=${T}/build

Icons: eveIcons.sql EVEIconsConverter
	${T}/EVEIconsConverter ./input/Icons/items ${T}/Icons

eveIcons.sql: EVEIconsIDsParser
	${T}/EVEIconsIDsParser ./input/sde/iconIDs.yaml ${T}/eveIcons.sql

Types: EVETypesConverter
	${T}/EVETypesConverter ./input/Types ${T}/Types ${T}/typesMap.sql

eufe.sqlite:
	cd ../../ThirdParty/eufe/dbinit; make OUTPUT_DIR=${PWD} DUMP=$(DUMP) T=${T} SDE=$(SDE)

createTables.sql: tmp
	sqlite3 ${SDE} ".read ./sql/tablesExtract.sql" > ${T}/tmp.sql
	sed 's/integer/int/g' ${T}/tmp.sql > ${T}/createTables.sql

npc.sql: EVENPCBuilder
	${T}/EVENPCBuilder ./input/npc.json ${T}/npc.sql

evedb.sqlite: createTables.sql Types eveIcons.sql npc.sql
	sqlite3 ${T}/evedb.sqlite ".read ${T}/createTables.sql"
	cd $(DUMP);	sqlite3 ${T}/evedb.sqlite ".read $(SQL)/dump.sql"
	sqlite3 ${SDE} ".read ./sql/evedb.sql"
	sqlite3 ${T}/evedb.sqlite ".read ../../ThirdParty/eufe/dbinit/sql/dumpPatch.sql"
	sqlite3 ${T}/evedb.sqlite ".read ${T}/eveIcons.sql"
	sqlite3 ${T}/evedb.sqlite ".read ${T}/npc.sql"
	sqlite3 ${T}/evedb.sqlite "CREATE INDEX \"npcGroup_parentNpcGroupID\" ON \"npcGroup\" (\"parentNpcGroupID\" ASC);"

NCDatabase.sqlite: NCDatabase evedb.sqlite Icons Types
	${T}/NCDatabase ./NCDatabase.sqlite ${T}/evedb.sqlite ${T}/Icons ${T}/Types ./input/Factions

tmp:
	mkdir -p ${T}

clean:
	rm -rf ${T}
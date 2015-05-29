CC=clang++
CFLAGS=-arch x86_64 -std=gnu++11 -stdlib=libc++ -lsqlite3
TMP+=${PWD}/tmp
DUMP=${PWD}/input/dump
VPATH=$(TMP)
SQL=${PWD}/sql

all: eufe.sqlite NCDatabase.sqlite

dbpatch: tmp
	$(CC) $(CFLAGS) ../dbpatch/dbpatch.cpp -o ./tmp/$@

EVEIconsConverter: tmp
	xcodebuild -project ../EVEIconsConverter/EVEIconsConverter.xcodeproj -configuration Release TARGET_BUILD_DIR=${TMP} OBJROOT=${TMP}/build SYMROOT=${TMP}/build

EVEIconsIDsParser: tmp
	xcodebuild -project ../EVEIconsIDsParser/EVEIconsIDsParser.xcodeproj -configuration Release TARGET_BUILD_DIR=${TMP} OBJROOT=${TMP}/build SYMROOT=${TMP}/build

EVETypesConverter: tmp
	xcodebuild -project ../EVETypesConverter/EVETypesConverter.xcodeproj -configuration Release TARGET_BUILD_DIR=${TMP} OBJROOT=${TMP}/build SYMROOT=${TMP}/build

EVENPCBuilder: tmp
	xcodebuild -project ../EVENPCBuilder/EVENPCBuilder.xcodeproj -configuration Release TARGET_BUILD_DIR=${TMP} OBJROOT=${TMP}/build SYMROOT=${TMP}/build

NCDatabase: tmp
	xcodebuild -project ../NCDatabase/NCDatabase.xcodeproj -configuration Release TARGET_BUILD_DIR=${TMP} OBJROOT=${TMP}/build SYMROOT=${TMP}/build

Icons: eveIcons.sql EVEIconsConverter
	$(TMP)/EVEIconsConverter ./input/Icons/items $(TMP)/Icons

eveIcons.sql: EVEIconsIDsParser
	$(TMP)/EVEIconsIDsParser ./input/sde/iconIDs.yaml $(TMP)/eveIcons.sql

Types: EVETypesConverter
	$(TMP)/EVETypesConverter ./input/Types $(TMP)/Types $(TMP)/typesMap.sql

eufe.sqlite:
	cd ../../ThirdParty/eufe/dbinit; make OUTPUT_DIR=${PWD} DUMP=$(DUMP) TMP=$(TMP)

createTables.sql: tmp
	sqlite3 ./input/sde/eve.sqlite ".read ./sql/tablesExtract.sql" > $(TMP)/tmp.sql
	sed 's/integer/int/g' $(TMP)/tmp.sql > $(TMP)/createTables.sql

npc.sql: EVENPCBuilder
	$(TMP)/EVENPCBuilder ./input/npc.json $(TMP)/npc.sql

evedb.sqlite: createTables.sql Types eveIcons.sql npc.sql
	sqlite3 $(TMP)/evedb.sqlite ".read $(TMP)/createTables.sql"
	cd $(DUMP);	sqlite3 $(TMP)/evedb.sqlite ".read $(SQL)/dump.sql"
	sqlite3 ./input/sde/eve.sqlite ".read ./sql/evedb.sql"
	sqlite3 $(TMP)/evedb.sqlite ".read ../../ThirdParty/eufe/dbinit/sql/dumpPatch.sql"
	sqlite3 $(TMP)/evedb.sqlite ".read $(TMP)/eveIcons.sql"
	sqlite3 $(TMP)/evedb.sqlite ".read $(TMP)/npc.sql"
	sqlite3 $(TMP)/evedb.sqlite "CREATE INDEX \"npcGroup_parentNpcGroupID\" ON \"npcGroup\" (\"parentNpcGroupID\" ASC);"

NCDatabase.sqlite: NCDatabase evedb.sqlite Icons Types
	$(TMP)/NCDatabase ./NCDatabase.sqlite $(TMP)/evedb.sqlite $(TMP)/Icons $(TMP)/Types ./input/Factions

tmp:
	mkdir -p $(TMP)

clean:
	rm -rf $(TMP)
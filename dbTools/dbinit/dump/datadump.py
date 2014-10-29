#-----------------------------------------------------------------------------
# Magic Hat - Cache dumping utility by Entity
# Freeware, use at your own risk.
#-----------------------------------------------------------------------------
# Make your own EVE SQL or XML data dump!
#
# Usage:
#
# - Edit the MODE below to XML or SQL depending on what you want
# - Edit the path to the correct location
# - Edit the output path to where you want the dumped data
# - Run script.
#
# Note that the SQL dumps produced are fairly simple and do not include the
# tables.
#-----------------------------------------------------------------------------

# want XML or SQL?
MODE = "SQL"

# where is EVE?
EVEPATH = "E:/Games/EVE"

# where to output the dump?
OUTPATH = "./"

#-----------------------------------------------------------------------------

from reverence import blue
import os
import ConfigParser

MODE = MODE.upper()
if MODE not in ("SQL", "XML"):
	raise RuntimeError("Unknown Mode:", MODE)

#eve = blue.EVE(EVEPATH, "87.237.38.50")
eve = blue.EVE(EVEPATH)
c = eve.getcachemgr()

#cachedObjects = c.LoadCacheFolder("BulkData")
#cachedObjects = c.LoadCachedFile("/dgmoperands.cache")
#cachedObjects = c.LoadCachedMethodCall(("dogma", "GetExpressionsForChar"))
#cachedObjects2 = c.LoadCacheFolder("CachedObjects")


	
#cachedObjects.update()

#-----------------------------------------------------------------------------

def xmlstr(value):
	# returns string that is safe to use in XML
	t = type(value)
	if t in (list, tuple, dict):
		raise ValueError("Unsupported type")
	if t is str:
		return repr(value.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;').replace("'",'&apos;'))[1:-1]
	elif t is unicode:
		return repr(value.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;').replace("'",'&apos;'))[2:-1]
	elif t == float:
		return value
	return repr(value)

def sqlstr(x):
	t = type(x)
	if t in (list, tuple, dict):
		raise ValueError("Unsupported type")
	if t is unicode:
		return repr(x)[1:].replace("\\'","''")
	if t is str:
		return repr(x).replace("\\'","''")
	if t is bool:
		#return repr(x).lower()
		if x:
			return "1"
		else:
			return "0"
	else:
		r = str(x)
		r = r.replace("e+", "E").replace("e-", "E-")
		if r.endswith(".0"):
			r = r[:-2]
		if r == "None":
			return "null"
		return r

#-----------------------------------------------------------------------------

def dump(objects, table):
	# see what we can pull out of the hat...
	f = []
	f2 = open( os.path.join(OUTPATH, table) + "." + MODE.lower(), "w")
	if (table == "dgmExpressions"):
			f.append("DROP TABLE IF EXISTS dgmExpressions;\nCREATE TABLE \"dgmExpressions\" (\n\"expressionID\"  INTEGER NOT NULL,\n\"operandID\"  INTEGER NOT NULL,\n\"arg1\"  INTEGER,\n\"arg2\"  INTEGER,\n\"expressionValue\"  TEXT,\n\"description\"  TEXT,\n\"expressionName\"  TEXT,\n\"expressionTypeID\"  INTEGER,\n\"expressionGroupID\"  INTEGER,\n\"expressionAttributeID\"  INTEGER,\nPRIMARY KEY (\"expressionID\")\n);")
	#	f.append("DROP TABLE IF EXISTS dgmExpressions;\nCREATE TABLE \"dgmExpressions\" (\n\"expressionID\"  INTEGER NOT NULL,\n\"operandID\"  INTEGER NOT NULL,\n\"operandKey\"  TEXT,\n\"arg1\"  INTEGER,\n\"arg2\"  INTEGER,\n\"expressionValue\"  TEXT,\n\"description\"  TEXT,\n\"expressionName\"  TEXT,\n\"expressionTypeID\"  INTEGER,\n\"expressionGroupID\"  INTEGER,\n\"expressionAttributeID\"  INTEGER,\n\"expressionCategoryID\"  INTEGER,\nPRIMARY KEY (\"expressionID\")\n);")
	elif (table == "dgmOperands"):
		f.append("DROP TABLE IF EXISTS dgmOperands;\nCREATE TABLE \"dgmOperands\" (\n\"operandID\"  INTEGER NOT NULL,\n\"operandKey\"  TEXT,\n\"description\"  TEXT,\n\"format\"  TEXT,\n\"arg1categoryID\"  INTEGER,\n\"arg2categoryID\"  INTEGER,\n\"resultCategoryID\"  INTEGER,\n\"pythonFormat\"  TEXT,\nPRIMARY KEY (\"operandID\")\n);")
	elif (table == "invTypes"):
		f.append("DROP TABLE IF EXISTS invTypes;\nCREATE TABLE invTypes (\n  \"typeID\"  INTEGER NOT NULL,\n  \"groupID\"  INTEGER,\n  \"typeName\" varchar(100) default NULL,\n  \"description\" varchar(3000) default NULL,\n  \"graphicID\" smallint(6) default NULL,\n  \"radius\" double default NULL,\n  \"mass\" double default NULL,\n  \"volume\" double default NULL,\n  \"capacity\" double default NULL,\n  \"portionSize\" int(11) default NULL,\n  \"raceID\" tinyint(3) default NULL,\n  \"basePrice\" double default NULL,\n  \"published\" tinyint(1) default NULL,\n  \"marketGroupID\" smallint(6) default NULL,\n  \"chanceOfDuplicating\" double default NULL,\n  soundID smallint(6) default NULL,\n  \"iconID\" smallint(6) default NULL,\n  dataID smallint(6) default NULL,\n  typeNameID smallint(6) default NULL,\n  descriptionID smallint(6) default NULL,\n  copyTypeID smallint(6) default NULL,\n  PRIMARY KEY  (\"typeID\")\n);")
	elif (table == "dgmTypeAttributes"):
		f.append("DROP TABLE IF EXISTS dgmTypeAttributes;\nCREATE TABLE \"dgmTypeAttributes\" (\n \"typeID\"  INTEGER NOT NULL,\n \"attributeID\"  INTEGER NOT NULL,\n \"value\"  double default NULL,\n PRIMARY KEY (\"typeID\", \"attributeID\")\n);")
	elif (table == "dgmAttributeTypes"):
		f.append("DROP TABLE IF EXISTS dgmAttributeTypes;\nCREATE TABLE dgmAttributeTypes (\n  \"attributeID\" smallint(6) NOT NULL,\n  \"attributeName\" varchar(100) default NULL,\n  attributeCategory smallint(6) NOT NULL,\n  \"description\" varchar(1000) default NULL,\n  maxAttributeID smallint(6) default NULL,\n  attributeIdx smallint(6) default NULL,\n  chargeRechargeTimeID smallint(6) default NULL,\n  \"defaultValue\" double default NULL,\n  \"published\" tinyint(1) default NULL,\n  \"displayName\" varchar(100) default NULL,\n  \"unitID\" tinyint(3) default NULL,\n  \"stackable\" tinyint(1) default NULL,\n  \"highIsGood\" tinyint(1) default NULL,\n  \"categoryID\" tinyint(3) default NULL,\n  \"iconID\" smallint(6) default NULL,\n  displayNameID smallint(6) default NULL,\n  tooltipTitleID smallint(6) default NULL,\n  tooltipDescriptionID smallint(6) default NULL,\n  dataID smallint(6) default NULL,\n  PRIMARY KEY  (\"attributeID\")\n);")
	elif (table == "dgmEffects"):
		f.append("DROP TABLE IF EXISTS dgmEffects;\nCREATE TABLE dgmEffects (\n\"effectID\"  INTEGER NOT NULL,\n\"effectName\"  TEXT(400),\n\"effectCategory\"  INTEGER,\n\"preExpression\"  INTEGER,\n\"postExpression\"  INTEGER,\n\"description\"  TEXT(1000),\n\"guid\"  TEXT(60),\n\"isOffensive\"  INTEGER,\n\"isAssistance\"  INTEGER,\n\"durationAttributeID\"  INTEGER,\n\"trackingSpeedAttributeID\"  INTEGER,\n\"dischargeAttributeID\"  INTEGER,\n\"rangeAttributeID\"  INTEGER,\n\"falloffAttributeID\"  INTEGER,\n\"disallowAutoRepeat\"  INTEGER,\n\"published\"  INTEGER,\n\"displayName\"  TEXT(100),\n\"isWarpSafe\"  INTEGER,\n\"rangeChance\"  INTEGER,\n\"electronicChance\"  INTEGER,\n\"propulsionChance\"  INTEGER,\n\"distribution\"  INTEGER,\n\"sfxName\"  TEXT(20),\n\"npcUsageChanceAttributeID\"  INTEGER,\n\"npcActivationChanceAttributeID\"  INTEGER,\n\"fittingUsageChanceAttributeID\"  INTEGER,\n\"iconID\" smallint(6) default NULL,\n\"displayNameID\" smallint(6) default NULL,\n\"descriptionID\" smallint(6) default NULL,\n\"modifierInfo\"  TEXT(1000),\n\"dataID\" smallint(6) default NULL,\nPRIMARY KEY (\"effectID\")\n);")
	elif (table == "dgmTypeEffects"):
		f.append("DROP TABLE IF EXISTS \"dgmTypeEffects\";\nCREATE TABLE \"dgmTypeEffects\" (\n\"typeID\"  INTEGER NOT NULL,\n\"effectID\"  INTEGER NOT NULL,\n\"isDefault\"  INTEGER,\nPRIMARY KEY (\"typeID\", \"effectID\")\n);")
	elif (table == "invCategories"):
		f.append("DROP TABLE IF EXISTS \"invCategories\";\nCREATE TABLE \"invCategories\" (\n\"categoryID\"  INTEGER NOT NULL,\n\"categoryName\"  TEXT(100),\n\"description\"  TEXT(3000),\n\"published\"  INTEGER,\n\"iconID\" smallint(6) default NULL,\n\"categoryNameID\" smallint(6) default NULL,\n\"dataID\" smallint(6) default NULL,\nPRIMARY KEY (\"categoryID\")\n);")
	elif (table == "invGroups"):
		f.append("DROP TABLE IF EXISTS \"invGroups\";\nCREATE TABLE \"invGroups\" (\n\"groupID\" INTEGER NOT NULL,\n\"categoryID\"  INTEGER,\n\"groupName\"  TEXT(100),\n\"description\"  TEXT(3000),\n\"useBasePrice\"  INTEGER,\n\"allowManufacture\"  INTEGER,\n\"allowRecycler\"  INTEGER,\n\"anchored\"  INTEGER,\n\"anchorable\"  INTEGER,\n\"fittableNonSingleton\"  INTEGER,\n\"published\"  INTEGER,\n\"iconID\"   smallint(6) default NULL,\n\"groupNameID\"   smallint(6) default NULL,\n\"dataID\"   smallint(6) default NULL,\nPRIMARY KEY (\"groupID\")\n);")
	elif (table == "invControlTowerResources"):
		f.append("DROP TABLE IF EXISTS invControlTowerResources;\nCREATE TABLE invControlTowerResources (\n  \"controlTowerTypeID\" int(11) NOT NULL,\n  \"resourceTypeID\" int(11) NOT NULL,\n  \"purpose\" tinyint(4) default NULL,\n  \"quantity\" int(11) default NULL,\n  \"minSecurityLevel\" double default NULL,\n  \"factionID\" int(11) default NULL,\n  \"wormholeClassID\" INTEGER default NULL,\n  PRIMARY KEY  (\"controlTowerTypeID\",\"resourceTypeID\")\n);")
	f.append("")
	f.append("BEGIN TRANSACTION;");
	
	if (table == "invControlTowerResources"):
		objects = objects.itervalues()
	elif (table == "dgmOperands"):
		objects = objects["lret"].itervalues();

	for obj in objects:#.itervalues():

		name = table
		item = name.split(".")[-1]
#		if item.isdigit():
			# stuff ending in numbers is pretty much irrelevant.
#			continue

		if item.startswith("Get"):
			item = item[3:]

		#print name, "...", 
		thing = obj

		# try to get "universal" header and lines lists by checking what
		# type the object is and grabbing the needed bits.
		header = lines = None
		guid = getattr(thing, "__guid__", None)
		if guid:
			if guid.startswith("util.Row"):
				header, lines = thing.header, thing.lines
			elif guid.startswith("util.IndexRow"):
				header, lines = thing.header, thing.items.values()
			elif guid == "dbutil.CRowset":
				header, lines = thing.header, thing
			elif guid == "dbutil.CIndexedRowset":
				header, lines = thing.header, thing.keys()
	#print thing.keys()
			elif guid == "util.FilterRowset":
				header = thing.header
				lines = []	
				for stuff in thing.items.itervalues():  # bad way to do this.
					lines += stuff
			elif guid == "blue.DBRow":
				header = thing.__header__
				lines = []
				lines.append(thing)

			else:
				print "UNSUPPORTED (%s)" % guid

		elif type(thing) == tuple:
			if len(thing) == 2:
				header, lines = thing

		elif type(thing) == list:
			row = thing[0]
			if hasattr(row, "__guid__"):
				if row.__guid__ == "blue.DBRow":
					header = row.__header__
					lines = thing
		else:
			print "UNKNOWN (%s)" % type(thing)
			continue

		if not header:
			print "NO HEADER (%s)" % type(thing)
			continue

		if type(header) is blue.DBRowDescriptor:
			header = header.Keys()

		# create XML file and dump the lines.
		try:
			if MODE == "XML":
				f.append("<?xml version='1.0' encoding='utf-8'?>\r\n<data>")
				for line in lines:
					f.append("\t<%s>" % item)
					for key,value in zip(header, line):
						if type(key) == tuple:
							key = key[0]
						f.append("\t\t<%s>%s</%s>" % (key, xmlstr(value), key))
					f.append("\t</%s>" % item)
				f.append("</data>")

			elif MODE == "SQL":
				#f.append("-- ObjectID: %s" % str(obj.objectID))
				for line in lines:
					line = ','.join([sqlstr(x) for x in line])
					f.append("INSERT INTO %s (%s) VALUES(%s);" % (item, ','.join(header), line))


			#print "OK"
		except:
			print "FAILED"
	# dump to file
	f.append("COMMIT TRANSACTION;");
	for line in f:
		print >>f2, line
	del f
	f2.close()

config = ConfigParser.RawConfigParser(allow_no_value=True)
config.read(os.path.join(EVEPATH, "start.ini"))
version = config.get("main", "version")
build = config.get("main", "build")

f = open( os.path.join(OUTPATH, "version.sql"), "w")
print >>f, "DROP TABLE IF EXISTS \"version\";\nCREATE TABLE \"version\" (\n\"build\"  INTEGER NOT NULL,\n\"version\"  TEXT(10));"
print >>f, "INSERT INTO version (build, version) VALUES (%s, \"%s\");" % (build, version)
f.close()

f = open( os.path.join(OUTPATH, "version.json"), "w")
print >>f, "{\"build\": %s, \"version\": \"%s\"}" % (build, version)
f.close()


#dump(c.LoadCachedMethodCall(("dogma", "GetExpressionsForChar")), "dgmExpressions");
dump(c.LoadCachedMethodCall(("dogma", "GetOperandsForChar")), "dgmOperands");
#dump(c.LoadCachedMethodCall(("marketProxy", "GetMarketGroups")), "invMarketGroups");
dump(c.LoadBulk("800003"), "dgmExpressions");
dump(c.LoadBulk("800004"), "dgmAttributeTypes");
dump(c.LoadBulk("800005"), "dgmEffects");
dump(c.LoadBulk("800007"), "dgmTypeEffects");
dump(c.LoadBulk("800006"), "dgmTypeAttributes");
dump(c.LoadBulk("600004"), "invTypes");
dump(c.LoadBulk("600002"), "invGroups");
dump(c.LoadBulk("600001"), "invCategories");
dump(c.LoadCachedMethodCall(("posMgr", "GetControlTowerFuelRequirements")), "invControlTowerResources");


#!/usr/bin/python
from sys import platform
from os.path import expanduser
import glob
import sys
import os
import pwd
import ConfigParser


from reverence import blue

import json
if platform == "darwin":
	EVEPATH = glob.glob(expanduser("~/Library/Application Support/EVE Online/p_drive/Local Settings/Application Data/CCP/EVE/SharedCache/wineenv/drive_c/tq"))[0]
else:
	EVEPATH = "E:/Games/EVE"

OUTPATH = "./"

user = pwd.getpwuid(os.getuid()).pw_name
path = "~/Library/Application Support/EVE Online/p_drive/Local Settings/Application Data/CCP/EVE/SharedCache/wineenv/drive_c/users/{0}/Local Settings/Application Data/CCP/EVE/c_tq_tranquility".format(user)
eve = blue.EVE(EVEPATH, cachepath=expanduser(path))
cfg = eve.getconfigmgr()

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
			return "true"
		else:
			return "false"
	else:
		r = str(x)
		r = r.replace("e+", "E").replace("e-", "E-")
		if r.endswith(".0"):
			r = r[:-2]
		if r == "None":
			return "null"
		return r

def dump(table, header, lines):
	# see what we can pull out of the hat...
	f = []
	f2 = open( os.path.join(OUTPATH, table) + ".json", "w")

	# create XML file and dump the lines.
	try:
		for line in lines:
			s = vars(line)
			line = ','.join(["\"%s\": %s" % (x, sqlstr(getattr(line, x))) if hasattr(line,x) else None for x in header])
			f.append("{%s}" % line)


		#print "OK"
	except:
		print "FAILED " + table

	print >>f2, "[%s]" % ",".join(f)
	del f
	f2.close()

def map(header, objects):
	return [objects.Get(key) for key in objects.keys()]


invTypeAttributesHeader = ("typeID", "attributeID", "value")
invTypeAttributes = [r for rows in cfg.dgmtypeattribs.values() for r in rows]

#dump ("invMarketGroups", invMarketGroupsHeader, invMarketGroups)
#dump ("dgmOperands", dgmOperandsHeader, dgmOperands)
#dump ("invCategories", invCategoriesHeader, invCategories)
#dump ("invGroups", invGroupsHeader, invGroups)
#dump ("invTypes", invTypesHeader, invTypes)
#dump ("dgmEffects", cfg.dgmeffects.header, cfg.dgmeffects.values())
#dump ("dgmTypeEffects", invTypeEffectsHeader, invTypeEffects)
#dump ("dgmExpressions", cfg.dgmexpressions.header, cfg.dgmexpressions.values())
#dump ("dgmAttributeTypes", cfg.dgmattribs.header, cfg.dgmattribs.values())
dump ("dgmTypeAttributes", invTypeAttributesHeader, invTypeAttributes)
#dump ("planetSchematics", planetSchematicsHeader, cfg.schematics.values())
#dump ("planetSchematicsPinMap", cfg.schematicspinmap.header, planetSchematicsPinMap)
#dump ("planetSchematicsTypeMap", cfg.schematicstypemap.header, planetSchematicsTypeMap)

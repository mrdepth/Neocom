#!/usr/bin/python
from sys import platform
from os.path import expanduser
import glob
import sys
import os
import pwd
import json

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

def dump(table, rows):
	array = []
	output = open( os.path.join(OUTPATH, table) + ".json", "w")

	try:
		for row in rows:
			array.append({x: row[x] for x in row.__keys__})
	except:
		print "FAILED " + table
	print >>output, json.dumps(array)
	del array
	output.close()

def map(header, objects):
	return [objects.Get(key) for key in objects.keys()]


dgmTypeAttributes = [r for rows in cfg.dgmtypeattribs.values() for r in rows]
dgmTypeEffects = [r for rows in cfg.dgmtypeeffects.values() for r in rows]
invMetaTypes = [r for rows in cfg.invmetatypes.items.values() for r in rows]
invMetaGroups = cfg.invmetagroups.items.values()
ramActivities = cfg.ramactivities.items.values()
ramAssemblyLineTypes = cfg.ramaltypes.items.values()
dump ("dgmTypeAttributes", dgmTypeAttributes)
dump ("dgmTypeEffects", dgmTypeEffects)
dump ("invMetaTypes", invMetaTypes)
dump ("invMetaGroups", invMetaGroups)
dump ("ramActivities", ramActivities)
dump ("ramAssemblyLineTypes", ramAssemblyLineTypes)

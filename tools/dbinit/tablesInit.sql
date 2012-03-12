CREATE TABLE "crtCategories" (
"categoryID"  INTEGER NOT NULL,
"description"  TEXT(500),
"categoryName"  TEXT(256),
PRIMARY KEY ("categoryID")
);
CREATE TABLE "crtCertificates" (
"certificateID"  INTEGER NOT NULL,
"categoryID"  INTEGER,
"classID"  INTEGER,
"grade"  INTEGER,
"corpID"  INTEGER,
"iconID"  INTEGER,
"description"  TEXT(500),
PRIMARY KEY ("certificateID")
);
CREATE TABLE "crtClasses" (
"classID"  INTEGER NOT NULL,
"description"  TEXT(500),
"className"  TEXT(256),
PRIMARY KEY ("classID")
);
CREATE TABLE "crtRecommendations" (
"recommendationID"  INTEGER NOT NULL,
"shipTypeID"  INTEGER,
"certificateID"  INTEGER,
"recommendationLevel"  INTEGER NOT NULL,
PRIMARY KEY ("recommendationID")
);
CREATE TABLE "crtRelationships" (
"relationshipID"  INTEGER NOT NULL,
"parentID"  INTEGER,
"parentTypeID"  INTEGER,
"parentLevel"  INTEGER,
"childID"  INTEGER,
PRIMARY KEY ("relationshipID")
);
CREATE TABLE "dgmAttributeCategories" (
"categoryID"  INTEGER NOT NULL,
"categoryName"  TEXT(50),
"categoryDescription"  TEXT(200),
PRIMARY KEY ("categoryID")
);
CREATE TABLE "eveIcons" (
"iconID"  INTEGER NOT NULL,
"iconFile"  TEXT(500) NOT NULL,
"description"  TEXT NOT NULL,
PRIMARY KEY ("iconID")
);
CREATE TABLE "eveUnits" (
"unitID"  INTEGER NOT NULL,
"unitName"  TEXT(100),
"displayName"  TEXT(50),
"description"  TEXT(1000),
PRIMARY KEY ("unitID")
);
CREATE TABLE "invControlTowerResourcePurposes" (
"purpose"  INTEGER NOT NULL,
"purposeText"  TEXT(100),
PRIMARY KEY ("purpose")
);
CREATE TABLE "invMarketGroups" (
"marketGroupID"  INTEGER NOT NULL,
"parentGroupID"  INTEGER,
"marketGroupName"  TEXT(100),
"description"  TEXT(3000),
"iconID"  INTEGER,
"hasTypes"  INTEGER,
PRIMARY KEY ("marketGroupID")
);
CREATE TABLE "invMetaGroups" (
"metaGroupID"  INTEGER NOT NULL,
"metaGroupName"  TEXT(100),
"description"  TEXT(1000),
"iconID"  INTEGER,
PRIMARY KEY ("metaGroupID")
);
CREATE TABLE "invMetaTypes" (
"typeID"  INTEGER NOT NULL,
"parentTypeID"  INTEGER,
"metaGroupID"  INTEGER,
PRIMARY KEY ("typeID")
);
CREATE TABLE "mapConstellations" (
"regionID"  INTEGER,
"constellationID"  INTEGER NOT NULL,
"constellationName"  TEXT(100),
"x"  REAL(53),
"y"  REAL(53),
"z"  REAL(53),
"xMin"  REAL(53),
"xMax"  REAL(53),
"yMin"  REAL(53),
"yMax"  REAL(53),
"zMin"  REAL(53),
"zMax"  REAL(53),
"factionID"  INTEGER,
"radius"  REAL(53),
PRIMARY KEY ("constellationID")
);
CREATE TABLE "mapDenormalize" (
"itemID"  INTEGER NOT NULL,
"typeID"  INTEGER,
"groupID"  INTEGER,
"solarSystemID"  INTEGER,
"constellationID"  INTEGER,
"regionID"  INTEGER,
"orbitID"  INTEGER,
"x"  REAL(53),
"y"  REAL(53),
"z"  REAL(53),
"radius"  REAL(53),
"itemName"  TEXT(100),
"security"  REAL(53),
"celestialIndex"  INTEGER,
"orbitIndex"  INTEGER,
PRIMARY KEY ("itemID")
);
CREATE TABLE "mapRegions" (
"regionID"  INTEGER NOT NULL,
"regionName"  TEXT(100),
"x"  REAL(53),
"y"  REAL(53),
"z"  REAL(53),
"xMin"  REAL(53),
"xMax"  REAL(53),
"yMin"  REAL(53),
"yMax"  REAL(53),
"zMin"  REAL(53),
"zMax"  REAL(53),
"factionID"  INTEGER,
"radius"  REAL(53),
PRIMARY KEY ("regionID")
);
CREATE TABLE "mapSolarSystems" (
"regionID"  INTEGER,
"constellationID"  INTEGER,
"solarSystemID"  INTEGER NOT NULL,
"solarSystemName"  TEXT(100),
"x"  REAL(53),
"y"  REAL(53),
"z"  REAL(53),
"xMin"  REAL(53),
"xMax"  REAL(53),
"yMin"  REAL(53),
"yMax"  REAL(53),
"zMin"  REAL(53),
"zMax"  REAL(53),
"luminosity"  REAL(53),
"border"  INTEGER,
"fringe"  INTEGER,
"corridor"  INTEGER,
"hub"  INTEGER,
"international"  INTEGER,
"regional"  INTEGER,
"constellation"  INTEGER,
"security"  REAL(53),
"factionID"  INTEGER,
"radius"  REAL(53),
"sunTypeID"  INTEGER,
"securityClass"  TEXT(2),
PRIMARY KEY ("solarSystemID")
);
CREATE TABLE "ramActivities" (
"activityID"  INTEGER NOT NULL,
"activityName"  TEXT(100),
"iconNo"  TEXT(5),
"description"  TEXT(1000),
"published"  INTEGER,
PRIMARY KEY ("activityID")
);
CREATE TABLE "staStations" (
"stationID"  INTEGER NOT NULL,
"security"  INTEGER,
"dockingCostPerVolume"  REAL(53),
"maxShipVolumeDockable"  REAL(53),
"officeRentalCost"  INTEGER,
"operationID"  INTEGER,
"stationTypeID"  INTEGER,
"corporationID"  INTEGER,
"solarSystemID"  INTEGER,
"constellationID"  INTEGER,
"regionID"  INTEGER,
"stationName"  TEXT(100),
"x"  REAL(53),
"y"  REAL(53),
"z"  REAL(53),
"reprocessingEfficiency"  REAL(53),
"reprocessingStationsTake"  REAL(53),
"reprocessingHangarFlag"  INTEGER,
PRIMARY KEY ("stationID")
);
CREATE TABLE dgmAttributeTypes (
  "attributeID" smallint(6) NOT NULL,
  "attributeName" varchar(100) default NULL,
  attributeCategory smallint(6) NOT NULL,
  "description" varchar(1000) default NULL,
  maxAttributeID smallint(6) NOT NULL,
  attributeIdx smallint(6) NOT NULL,
  chargeRechargeTimeID smallint(6) NOT NULL,
  "defaultValue" double default NULL,
  "published" tinyint(1) default NULL,
  "displayName" varchar(100) default NULL,
  "unitID" tinyint(3) default NULL,
  "stackable" tinyint(1) default NULL,
  "highIsGood" tinyint(1) default NULL,
  "categoryID" tinyint(3) default NULL,
  "iconID" smallint(6) default NULL,
  displayNameID smallint(6) default NULL,
  dataID smallint(6) default NULL,
  PRIMARY KEY  ("attributeID")
);

CREATE TABLE dgmEffects (
"effectID"  INTEGER NOT NULL,
"effectName"  TEXT(400),
"effectCategory"  INTEGER,
"preExpression"  INTEGER,
"postExpression"  INTEGER,
"description"  TEXT(1000),
"guid"  TEXT(60),
"isOffensive"  INTEGER,
"isAssistance"  INTEGER,
"durationAttributeID"  INTEGER,
"trackingSpeedAttributeID"  INTEGER,
"dischargeAttributeID"  INTEGER,
"rangeAttributeID"  INTEGER,
"falloffAttributeID"  INTEGER,
"disallowAutoRepeat"  INTEGER,
"published"  INTEGER,
"displayName"  TEXT(100),
"isWarpSafe"  INTEGER,
"rangeChance"  INTEGER,
"electronicChance"  INTEGER,
"propulsionChance"  INTEGER,
"distribution"  INTEGER,
"sfxName"  TEXT(20),
"npcUsageChanceAttributeID"  INTEGER,
"npcActivationChanceAttributeID"  INTEGER,
"fittingUsageChanceAttributeID"  INTEGER,
"iconID" smallint(6) default NULL,
"displayNameID" smallint(6) default NULL,
"descriptionID" smallint(6) default NULL,
"dataID" smallint(6) default NULL,
PRIMARY KEY ("effectID")
);
CREATE TABLE "dgmTypeAttributes" (
 "typeID"  INTEGER NOT NULL,
 "attributeID"  INTEGER NOT NULL,
 "value"  double default NULL,
 PRIMARY KEY ("typeID", "attributeID")
);

CREATE TABLE "dgmTypeEffects" (
"typeID"  INTEGER NOT NULL,
"effectID"  INTEGER NOT NULL,
"isDefault"  INTEGER,
PRIMARY KEY ("typeID", "effectID")
);

CREATE TABLE "invCategories" (
"categoryID"  INTEGER NOT NULL,
"categoryName"  TEXT(100),
"description"  TEXT(3000),
"published"  INTEGER,
"iconID" smallint(6) default NULL,
"categoryNameID" smallint(6) default NULL,
"dataID" smallint(6) default NULL,
PRIMARY KEY ("categoryID")
);
CREATE TABLE "invGroups" (
"groupID"  INTEGER NOT NULL,
"categoryID"  INTEGER,
"groupName"  TEXT(100),
"description"  TEXT(3000),
"useBasePrice"  INTEGER,
"allowManufacture"  INTEGER,
"allowRecycler"  INTEGER,
"anchored"  INTEGER,
"anchorable"  INTEGER,
"fittableNonSingleton"  INTEGER,
"published"  INTEGER,
"iconID"   smallint(6) default NULL,
"groupNameID"   smallint(6) default NULL,
"dataID"   smallint(6) default NULL,
PRIMARY KEY ("groupID")
);
CREATE TABLE invTypes (
  "typeID" int(11) NOT NULL,
  "groupID" smallint(6) default NULL,
  "typeName" varchar(100) default NULL,
  "description" varchar(3000) default NULL,
  "graphicID" smallint(6) default NULL,
  "radius" double default NULL,
  "mass" double default NULL,
  "volume" double default NULL,
  "capacity" double default NULL,
  "portionSize" int(11) default NULL,
  "raceID" tinyint(3) default NULL,
  "basePrice" double default NULL,
  "published" tinyint(1) default NULL,
  "marketGroupID" smallint(6) default NULL,
  "chanceOfDuplicating" double default NULL,
  soundID smallint(6) default NULL,
  "iconID" smallint(6) default NULL,
  dataID smallint(6) default NULL,
  typeNameID smallint(6) default NULL,
  descriptionID smallint(6) default NULL,
  PRIMARY KEY  ("typeID")
);

CREATE TABLE invControlTowerResources (
  "controlTowerTypeID" int(11) NOT NULL,
  "resourceTypeID" int(11) NOT NULL,
  "purpose" tinyint(4) default NULL,
  "quantity" int(11) default NULL,
  "minSecurityLevel" double default NULL,
  "factionID" int(11) default NULL,
  "wormholeClassID" INTEGER default NULL,
  PRIMARY KEY  ("controlTowerTypeID","resourceTypeID")
);


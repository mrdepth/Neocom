CREATE TABLE "crtCategories" (
  "categoryID" tinyint(3) NOT NULL,
  "description" varchar(500) DEFAULT NULL,
  "categoryName" varchar(256) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);

CREATE TABLE "crtCertificates" (
  "certificateID" int(11) NOT NULL,
  "categoryID" tinyint(3) DEFAULT NULL,
  "classID" int(11) DEFAULT NULL,
  "grade" tinyint(4) DEFAULT NULL,
  "corpID" int(11) DEFAULT NULL,
  "iconID" smallint(6) DEFAULT NULL,
  "description" varchar(500) DEFAULT NULL,
  PRIMARY KEY ("certificateID")
);

CREATE TABLE "crtClasses" (
  "classID" int(11) NOT NULL,
  "description" varchar(500) DEFAULT NULL,
  "className" varchar(256) DEFAULT NULL,
  PRIMARY KEY ("classID")
);

CREATE TABLE "crtRecommendations" (
  "recommendationID" int(11) NOT NULL,
  "shipTypeID" int(11) DEFAULT NULL,
  "certificateID" int(11) DEFAULT NULL,
  "recommendationLevel" tinyint(4) NOT NULL,
  PRIMARY KEY ("recommendationID")
);

CREATE TABLE "crtRelationships" (
  "relationshipID" int(11) NOT NULL,
  "parentID" int(11) DEFAULT NULL,
  "parentTypeID" int(11) DEFAULT NULL,
  "parentLevel" tinyint(4) DEFAULT NULL,
  "childID" int(11) DEFAULT NULL,
  PRIMARY KEY ("relationshipID")
);

CREATE TABLE "dgmAttributeCategories" (
  "categoryID" tinyint(3) NOT NULL,
  "categoryName" varchar(50) DEFAULT NULL,
  "categoryDescription" varchar(200) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);

CREATE TABLE "eveIcons" (
  "iconID" smallint(6) NOT NULL DEFAULT '0',
  "iconFile" varchar(500) NOT NULL,
  "description" varchar(16000) NOT NULL,
  PRIMARY KEY ("iconID")
);

CREATE TABLE "eveUnits" (
  "unitID" tinyint(3) NOT NULL,
  "unitName" varchar(100) DEFAULT NULL,
  "displayName" varchar(50) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  PRIMARY KEY ("unitID")
);

CREATE TABLE "invControlTowerResourcePurposes" (
  "purpose" tinyint(4) NOT NULL,
  "purposeText" varchar(100) DEFAULT NULL,
  PRIMARY KEY ("purpose")
);

CREATE TABLE "invMarketGroups" (
  "marketGroupID" smallint(6) NOT NULL,
  "parentGroupID" smallint(6) DEFAULT NULL,
  "marketGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(3000) DEFAULT NULL,
  "iconID" smallint(6) DEFAULT NULL,
  "hasTypes" tinyint(1) DEFAULT NULL,
  PRIMARY KEY ("marketGroupID")
);

CREATE TABLE "invMetaGroups" (
  "metaGroupID" smallint(6) NOT NULL,
  "metaGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "iconID" smallint(6) DEFAULT NULL,
  PRIMARY KEY ("metaGroupID")
);

CREATE TABLE "invMetaTypes" (
  "typeID" int(11) NOT NULL,
  "parentTypeID" int(11) DEFAULT NULL,
  "metaGroupID" smallint(6) DEFAULT NULL,
  PRIMARY KEY ("typeID")
);

CREATE TABLE "mapConstellations" (
  "regionID" int(11) DEFAULT NULL,
  "constellationID" int(11) NOT NULL,
  "constellationName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "xMin" double DEFAULT NULL,
  "xMax" double DEFAULT NULL,
  "yMin" double DEFAULT NULL,
  "yMax" double DEFAULT NULL,
  "zMin" double DEFAULT NULL,
  "zMax" double DEFAULT NULL,
  "factionID" int(11) DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("constellationID")
);

CREATE TABLE "mapDenormalize" (
  "itemID" int(11) NOT NULL,
  "typeID" int(11) DEFAULT NULL,
  "groupID" smallint(6) DEFAULT NULL,
  "solarSystemID" int(11) DEFAULT NULL,
  "constellationID" int(11) DEFAULT NULL,
  "regionID" int(11) DEFAULT NULL,
  "orbitID" int(11) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "itemName" varchar(100) DEFAULT NULL,
  "security" double DEFAULT NULL,
  "celestialIndex" tinyint(4) DEFAULT NULL,
  "orbitIndex" tinyint(4) DEFAULT NULL,
  PRIMARY KEY ("itemID")
);

CREATE TABLE "mapRegions" (
  "regionID" int(11) NOT NULL,
  "regionName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "xMin" double DEFAULT NULL,
  "xMax" double DEFAULT NULL,
  "yMin" double DEFAULT NULL,
  "yMax" double DEFAULT NULL,
  "zMin" double DEFAULT NULL,
  "zMax" double DEFAULT NULL,
  "factionID" int(11) DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("regionID")
);

CREATE TABLE "mapSolarSystems" (
  "regionID" int(11) DEFAULT NULL,
  "constellationID" int(11) DEFAULT NULL,
  "solarSystemID" int(11) NOT NULL,
  "solarSystemName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "xMin" double DEFAULT NULL,
  "xMax" double DEFAULT NULL,
  "yMin" double DEFAULT NULL,
  "yMax" double DEFAULT NULL,
  "zMin" double DEFAULT NULL,
  "zMax" double DEFAULT NULL,
  "luminosity" double DEFAULT NULL,
  "border" tinyint(1) DEFAULT NULL,
  "fringe" tinyint(1) DEFAULT NULL,
  "corridor" tinyint(1) DEFAULT NULL,
  "hub" tinyint(1) DEFAULT NULL,
  "international" tinyint(1) DEFAULT NULL,
  "regional" tinyint(1) DEFAULT NULL,
  "constellation" tinyint(1) DEFAULT NULL,
  "security" double DEFAULT NULL,
  "factionID" int(11) DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "sunTypeID" int(11) DEFAULT NULL,
  "securityClass" varchar(2) DEFAULT NULL,
  PRIMARY KEY ("solarSystemID")
);

CREATE TABLE "ramActivities" (
  "activityID" tinyint(3) NOT NULL,
  "activityName" varchar(100) DEFAULT NULL,
  "iconNo" varchar(5) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "published" tinyint(1) DEFAULT NULL,
  PRIMARY KEY ("activityID")
);

CREATE TABLE "staStations" (
  "stationID" int(11) NOT NULL,
  "security" smallint(6) DEFAULT NULL,
  "dockingCostPerVolume" double DEFAULT NULL,
  "maxShipVolumeDockable" double DEFAULT NULL,
  "officeRentalCost" int(11) DEFAULT NULL,
  "operationID" tinyint(3) DEFAULT NULL,
  "stationTypeID" int(11) DEFAULT NULL,
  "corporationID" int(11) DEFAULT NULL,
  "solarSystemID" int(11) DEFAULT NULL,
  "constellationID" int(11) DEFAULT NULL,
  "regionID" int(11) DEFAULT NULL,
  "stationName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "reprocessingEfficiency" double DEFAULT NULL,
  "reprocessingStationsTake" double DEFAULT NULL,
  "reprocessingHangarFlag" tinyint(4) DEFAULT NULL,
  PRIMARY KEY ("stationID")
);

CREATE INDEX "crtCertificates_IX_category" ON "crtCertificates" ("categoryID");
CREATE INDEX "crtCertificates_IX_class" ON "crtCertificates" ("classID");
CREATE INDEX "crtCertificates_IX_corpID" ON "crtCertificates" ("corpID");
CREATE INDEX "crtCertificates_IX_iconID" ON "crtCertificates" ("iconID");
CREATE INDEX "crtRecommendations_IX_certificate" ON "crtRecommendations" ("certificateID");
CREATE INDEX "crtRecommendations_IX_shipType" ON "crtRecommendations" ("shipTypeID");
CREATE INDEX "crtRelationships_IX_child" ON "crtRelationships" ("childID");
CREATE INDEX "crtRelationships_IX_parent" ON "crtRelationships" ("parentID");
CREATE INDEX "crtRelationships_IX_parentTypeID" ON "crtRelationships" ("parentTypeID");
CREATE INDEX "invMarketGroups_IX_parentGroupID" ON "invMarketGroups" ("parentGroupID");
CREATE INDEX "invMarketGroups_IX_iconID" ON "invMarketGroups" ("iconID");
CREATE INDEX "invMetaGroups_IX_iconID" ON "invMetaGroups" ("iconID");
CREATE INDEX "invMetaTypes_IX_parentTypeID" ON "invMetaTypes" ("parentTypeID");
CREATE INDEX "invMetaTypes_IX_metaGroupID" ON "invMetaTypes" ("metaGroupID");
CREATE UNIQUE INDEX "mapConstellations_IX_constellationID" ON "mapConstellations" ("constellationID","regionID");
CREATE INDEX "mapConstellations_IX_region" ON "mapConstellations" ("regionID");
CREATE INDEX "mapConstellations_IX_factionID" ON "mapConstellations" ("factionID");
CREATE INDEX "mapDenormalize_IX_constellation" ON "mapDenormalize" ("constellationID");
CREATE INDEX "mapDenormalize_IX_groupConstellation" ON "mapDenormalize" ("groupID","constellationID");
CREATE INDEX "mapDenormalize_IX_groupRegion" ON "mapDenormalize" ("groupID","regionID");
CREATE INDEX "mapDenormalize_IX_groupSystem" ON "mapDenormalize" ("groupID","solarSystemID");
CREATE INDEX "mapDenormalize_IX_orbit" ON "mapDenormalize" ("orbitID");
CREATE INDEX "mapDenormalize_IX_region" ON "mapDenormalize" ("regionID");
CREATE INDEX "mapDenormalize_IX_system" ON "mapDenormalize" ("solarSystemID");
CREATE INDEX "mapDenormalize_IX_typeID" ON "mapDenormalize" ("typeID");
CREATE INDEX "mapRegions_IX_factionID" ON "mapRegions" ("factionID");
CREATE UNIQUE INDEX "mapSolarSystems_IX_solarSystemID" ON "mapSolarSystems" ("solarSystemID","constellationID","regionID");
CREATE INDEX "mapSolarSystems_IX_constellation" ON "mapSolarSystems" ("constellationID");
CREATE INDEX "mapSolarSystems_IX_region" ON "mapSolarSystems" ("regionID");
CREATE INDEX "mapSolarSystems_IX_security" ON "mapSolarSystems" ("security");
CREATE INDEX "mapSolarSystems_IX_factionID" ON "mapSolarSystems" ("factionID");
CREATE INDEX "mapSolarSystems_IX_sunTypeID" ON "mapSolarSystems" ("sunTypeID");
CREATE INDEX "staStations_IX_constellation" ON "staStations" ("constellationID");
CREATE INDEX "staStations_IX_corporation" ON "staStations" ("corporationID");
CREATE INDEX "staStations_IX_operation" ON "staStations" ("operationID");
CREATE INDEX "staStations_IX_region" ON "staStations" ("regionID");
CREATE INDEX "staStations_IX_system" ON "staStations" ("solarSystemID");
CREATE INDEX "staStations_IX_type" ON "staStations" ("stationTypeID");
CREATE INDEX "staStations_IX_solarSystemID" ON "staStations" ("solarSystemID","constellationID","regionID");
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
  copyTypeID smallint(6) default NULL,
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


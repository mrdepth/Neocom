CREATE TABLE "certCerts" (
  "certID" int NOT NULL,
  "description" text,
  "groupid" int DEFAULT NULL,
  "name" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("certID")
);
CREATE TABLE "certMasteries" (
  "typeID" int DEFAULT NULL,
  "masteryLevel" int DEFAULT NULL,
  "certID" int DEFAULT NULL
);
CREATE TABLE "certSkills" (
  "certID" int DEFAULT NULL,
  "skillID" int DEFAULT NULL,
  "certLevelInt" int DEFAULT NULL,
  "skillLevel" int DEFAULT NULL,
  "certLevelText" varchar(8) DEFAULT NULL
);
CREATE TABLE "chrRaces" (
  "raceID" int  NOT NULL,
  "raceName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "iconID" int DEFAULT NULL,
  "shortDescription" varchar(500) DEFAULT NULL,
  PRIMARY KEY ("raceID")
);
CREATE TABLE "dgmAttributeCategories" (
  "categoryID" int  NOT NULL,
  "categoryName" varchar(50) DEFAULT NULL,
  "categoryDescription" varchar(200) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);
CREATE TABLE "eveUnits" (
  "unitID" int  NOT NULL,
  "unitName" varchar(100) DEFAULT NULL,
  "displayName" varchar(50) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  PRIMARY KEY ("unitID")
);
CREATE TABLE "industryActivity" (
  "typeID" int NOT NULL DEFAULT '0',
  "time" int DEFAULT NULL,
  "activityID" int NOT NULL DEFAULT '0',
  PRIMARY KEY ("typeID","activityID")
);

CREATE TABLE "industryActivityMaterials" (
  "typeID" int DEFAULT NULL,
  "activityID" int DEFAULT NULL,
  "materialTypeID" int DEFAULT NULL,
  "quantity" int DEFAULT NULL,
  "consume" int DEFAULT '1'
);
CREATE TABLE "industryActivityProbabilities" (
  "typeID" int DEFAULT NULL,
  "activityID" int DEFAULT NULL,
  "productTypeID" int DEFAULT NULL,
  "probability" decimal(3,2) DEFAULT NULL
);
CREATE TABLE "industryActivityProducts" (
  "typeID" int DEFAULT NULL,
  "activityID" int DEFAULT NULL,
  "productTypeID" int DEFAULT NULL,
  "quantity" int DEFAULT NULL
);
CREATE TABLE "industryActivitySkills" (
  "typeID" int DEFAULT NULL,
  "activityID" int DEFAULT NULL,
  "skillID" int DEFAULT NULL,
  "level" int DEFAULT NULL
);
CREATE TABLE "industryBlueprints" (
  "typeID" int NOT NULL,
  "maxProductionLimit" int DEFAULT NULL,
  PRIMARY KEY ("typeID")
);
CREATE TABLE "invControlTowerResourcePurposes" (
  "purpose" int  NOT NULL,
  "purposeText" varchar(100) DEFAULT NULL,
  PRIMARY KEY ("purpose")
);
CREATE TABLE "invMarketGroups" (
  "marketGroupID" int NOT NULL,
  "parentGroupID" int DEFAULT NULL,
  "marketGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(3000) DEFAULT NULL,
  "iconID" int DEFAULT NULL,
  "hasTypes" int DEFAULT NULL,
  PRIMARY KEY ("marketGroupID")
);
CREATE TABLE "invMetaGroups" (
  "metaGroupID" int NOT NULL,
  "metaGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "iconID" int DEFAULT NULL,
  PRIMARY KEY ("metaGroupID")
);
CREATE TABLE "invMetaTypes" (
  "typeID" int NOT NULL,
  "parentTypeID" int DEFAULT NULL,
  "metaGroupID" int DEFAULT NULL,
  PRIMARY KEY ("typeID")
);
CREATE TABLE "invTraits" (
  "typeID" int DEFAULT NULL,
  "skillID" int DEFAULT NULL,
  "bonus" double DEFAULT NULL,
  "bonusText" text,
  "unitID" int DEFAULT NULL
);
CREATE TABLE "invTypeMaterials" (
  "typeID" int NOT NULL,
  "materialTypeID" int NOT NULL,
  "quantity" int NOT NULL DEFAULT '0',
  PRIMARY KEY ("typeID","materialTypeID")
);

CREATE TABLE "mapConstellations" (
  "regionID" int DEFAULT NULL,
  "constellationID" int NOT NULL,
  "constellationName" longtext,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "xMin" double DEFAULT NULL,
  "xMax" double DEFAULT NULL,
  "yMin" double DEFAULT NULL,
  "yMax" double DEFAULT NULL,
  "zMin" double DEFAULT NULL,
  "zMax" double DEFAULT NULL,
  "factionID" int DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("constellationID")
);
CREATE TABLE "mapDenormalize" (
  "itemID" int NOT NULL,
  "typeID" int DEFAULT NULL,
  "groupID" int DEFAULT NULL,
  "solarSystemID" int DEFAULT NULL,
  "constellationID" int DEFAULT NULL,
  "regionID" int DEFAULT NULL,
  "orbitID" int DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "itemName" longtext,
  "security" double DEFAULT NULL,
  "celestialIndex" int DEFAULT NULL,
  "orbitIndex" int DEFAULT NULL,
  PRIMARY KEY ("itemID")
);
CREATE TABLE "mapRegions" (
  "regionID" int NOT NULL,
  "regionName" longtext,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "xMin" double DEFAULT NULL,
  "xMax" double DEFAULT NULL,
  "yMin" double DEFAULT NULL,
  "yMax" double DEFAULT NULL,
  "zMin" double DEFAULT NULL,
  "zMax" double DEFAULT NULL,
  "factionID" int DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("regionID")
);
CREATE TABLE "mapSolarSystems" (
  "regionID" int DEFAULT NULL,
  "constellationID" int DEFAULT NULL,
  "solarSystemID" int NOT NULL,
  "solarSystemName" longtext,
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
  "border" int DEFAULT NULL,
  "fringe" int DEFAULT NULL,
  "corridor" int DEFAULT NULL,
  "hub" int DEFAULT NULL,
  "international" int DEFAULT NULL,
  "regional" int DEFAULT NULL,
  "constellation" int DEFAULT NULL,
  "security" double DEFAULT NULL,
  "factionID" int DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "sunTypeID" int DEFAULT NULL,
  "securityClass" longtext,
  PRIMARY KEY ("solarSystemID")
);
CREATE TABLE "ramActivities" (
  "activityID" int  NOT NULL,
  "activityName" varchar(100) DEFAULT NULL,
  "iconNo" varchar(5) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "published" int DEFAULT NULL,
  PRIMARY KEY ("activityID")
);
CREATE TABLE "ramAssemblyLineTypes" (
  "assemblyLineTypeID" int  NOT NULL,
  "assemblyLineTypeName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "baseTimeMultiplier" double DEFAULT NULL,
  "baseMaterialMultiplier" double DEFAULT NULL,
  "baseCostMultiplier" double DEFAULT NULL,
  "volume" double DEFAULT NULL,
  "activityID" int  DEFAULT NULL,
  "minCostPerHour" double DEFAULT NULL,
  PRIMARY KEY ("assemblyLineTypeID")
);
CREATE TABLE "ramInstallationTypeContents" (
  "installationTypeID" int NOT NULL,
  "assemblyLineTypeID" int  NOT NULL,
  "quantity" int  DEFAULT NULL,
  PRIMARY KEY ("installationTypeID","assemblyLineTypeID")
);

CREATE TABLE "staStations" (
  "stationID" int NOT NULL,
  "security" int DEFAULT NULL,
  "dockingCostPerVolume" double DEFAULT NULL,
  "maxShipVolumeDockable" double DEFAULT NULL,
  "officeRentalCost" int DEFAULT NULL,
  "operationID" int  DEFAULT NULL,
  "stationTypeID" int DEFAULT NULL,
  "corporationID" int DEFAULT NULL,
  "solarSystemID" int DEFAULT NULL,
  "constellationID" int DEFAULT NULL,
  "regionID" int DEFAULT NULL,
  "stationName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "reprocessingEfficiency" double DEFAULT NULL,
  "reprocessingStationsTake" double DEFAULT NULL,
  "reprocessingHangarFlag" int  DEFAULT NULL,
  PRIMARY KEY ("stationID")
);
CREATE INDEX "staStations_staStations_IX_region" ON "staStations" ("regionID");
CREATE INDEX "staStations_staStations_IX_system" ON "staStations" ("solarSystemID");
CREATE INDEX "staStations_staStations_IX_constellation" ON "staStations" ("constellationID");
CREATE INDEX "staStations_staStations_IX_operation" ON "staStations" ("operationID");
CREATE INDEX "staStations_staStations_IX_type" ON "staStations" ("stationTypeID");
CREATE INDEX "staStations_staStations_IX_corporation" ON "staStations" ("corporationID");
CREATE INDEX "industryActivitySkills_typeID" ON "industryActivitySkills" ("typeID");
CREATE INDEX "industryActivitySkills_typeID_2" ON "industryActivitySkills" ("typeID","activityID");
CREATE INDEX "mapRegions_mapRegions_IX_region" ON "mapRegions" ("regionID");
CREATE INDEX "industryActivityMaterials_typeID" ON "industryActivityMaterials" ("typeID");
CREATE INDEX "industryActivityMaterials_typeID_2" ON "industryActivityMaterials" ("typeID","activityID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupRegion" ON "mapDenormalize" ("groupID","regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupConstellation" ON "mapDenormalize" ("groupID","constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupSystem" ON "mapDenormalize" ("groupID","solarSystemID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_system" ON "mapDenormalize" ("solarSystemID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_constellation" ON "mapDenormalize" ("constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_region" ON "mapDenormalize" ("regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_orbit" ON "mapDenormalize" ("orbitID");
CREATE INDEX "mapDenormalize_mapDenormalize_gis" ON "mapDenormalize" ("solarSystemID","x","y","z","itemName","itemID");
CREATE INDEX "mapConstellations_mapConstellations_IX_region" ON "mapConstellations" ("regionID");
CREATE INDEX "industryActivityProbabilities_typeID" ON "industryActivityProbabilities" ("typeID");
CREATE INDEX "industryActivityProbabilities_typeID_2" ON "industryActivityProbabilities" ("typeID","activityID");
CREATE INDEX "industryActivityProbabilities_productTypeID" ON "industryActivityProbabilities" ("productTypeID");
CREATE INDEX "industryActivity_activityID" ON "industryActivity" ("activityID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_region" ON "mapSolarSystems" ("regionID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_constellation" ON "mapSolarSystems" ("constellationID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_security" ON "mapSolarSystems" ("security");
CREATE INDEX "mapSolarSystems_mss_name" ON "mapSolarSystems" ("solarSystemName");
CREATE INDEX "industryActivityProducts_typeID" ON "industryActivityProducts" ("typeID");
CREATE INDEX "industryActivityProducts_typeID_2" ON "industryActivityProducts" ("typeID","activityID");
CREATE INDEX "industryActivityProducts_productTypeID" ON "industryActivityProducts" ("productTypeID");
CREATE TABLE dgmAttributeTypes (
  "attributeID" smallint(6) NOT NULL,
  "attributeName" varchar(100) default NULL,
  attributeCategory smallint(6) NOT NULL,
  "description" varchar(1000) default NULL,
  maxAttributeID smallint(6) default NULL,
  attributeIdx smallint(6) default NULL,
  chargeRechargeTimeID smallint(6) default NULL,
  "defaultValue" double default NULL,
  "published" tinyint(1) default NULL,
  "displayName" varchar(100) default NULL,
  "unitID" tinyint(3) default NULL,
  "stackable" tinyint(1) default NULL,
  "highIsGood" tinyint(1) default NULL,
  "categoryID" tinyint(3) default NULL,
  "iconID" smallint(6) default NULL,
  displayNameID smallint(6) default NULL,
  tooltipTitleID smallint(6) default NULL,
  tooltipDescriptionID smallint(6) default NULL,
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
"modifierInfo"  TEXT(1000),
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
"groupID" INTEGER NOT NULL,
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
  "typeID"  INTEGER NOT NULL,
  "groupID"  INTEGER,
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



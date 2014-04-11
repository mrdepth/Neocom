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
CREATE TABLE "dgmAttributeCategories" (
  "categoryID" int  NOT NULL,
  "categoryName" varchar(100) DEFAULT NULL,
  "categoryDescription" varchar(400) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);
CREATE TABLE "eveUnits" (
  "unitID" int  NOT NULL,
  "unitName" varchar(100) DEFAULT NULL,
  "displayName" varchar(50) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  PRIMARY KEY ("unitID")
);
CREATE TABLE "invBlueprintTypes" (
  "blueprintTypeID" int NOT NULL,
  "parentBlueprintTypeID" int DEFAULT NULL,
  "productTypeID" int DEFAULT NULL,
  "productionTime" int DEFAULT NULL,
  "techLevel" int DEFAULT NULL,
  "researchProductivityTime" int DEFAULT NULL,
  "researchMaterialTime" int DEFAULT NULL,
  "researchCopyTime" int DEFAULT NULL,
  "researchTechTime" int DEFAULT NULL,
  "productivityModifier" int DEFAULT NULL,
  "materialModifier" int DEFAULT NULL,
  "wasteFactor" int DEFAULT NULL,
  "maxProductionLimit" int DEFAULT NULL,
  PRIMARY KEY ("blueprintTypeID")
);
CREATE TABLE "invControlTowerResourcePurposes" (
  "purpose" int  NOT NULL,
  "purposeText" varchar(100) DEFAULT NULL,
  PRIMARY KEY ("purpose")
);
CREATE TABLE "invMarketGroups" (
  "marketGroupID" int NOT NULL,
  "parentGroupID" int DEFAULT NULL,
  "marketGroupName" varchar(200) DEFAULT NULL,
  "description" varchar(6000) DEFAULT NULL,
  "iconID" int DEFAULT NULL,
  "hasTypes" int DEFAULT NULL,
  PRIMARY KEY ("marketGroupID")
);
CREATE TABLE "invMetaGroups" (
  "metaGroupID" int NOT NULL,
  "metaGroupName" varchar(200) DEFAULT NULL,
  "description" varchar(2000) DEFAULT NULL,
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
  "bonus" int DEFAULT NULL,
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
  "constellationID" int NOT NULL DEFAULT '0',
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
  "itemID" int NOT NULL DEFAULT '0',
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
  "regionID" int NOT NULL DEFAULT '0',
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
  "solarSystemID" int NOT NULL DEFAULT '0',
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
  "activityName" varchar(200) DEFAULT NULL,
  "iconNo" varchar(5) DEFAULT NULL,
  "description" varchar(2000) DEFAULT NULL,
  "published" int DEFAULT NULL,
  PRIMARY KEY ("activityID")
);
CREATE TABLE "ramAssemblyLineTypes" (
  "assemblyLineTypeID" int  NOT NULL,
  "assemblyLineTypeName" varchar(200) DEFAULT NULL,
  "description" varchar(2000) DEFAULT NULL,
  "baseTimeMultiplier" double DEFAULT NULL,
  "baseMaterialMultiplier" double DEFAULT NULL,
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

CREATE TABLE "ramTypeRequirements" (
  "typeID" int NOT NULL,
  "activityID" int  NOT NULL,
  "requiredTypeID" int NOT NULL,
  "quantity" int DEFAULT NULL,
  "damagePerJob" double DEFAULT NULL,
  "recycle" int DEFAULT NULL,
  PRIMARY KEY ("typeID","activityID","requiredTypeID")
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
  "stationName" varchar(200) DEFAULT NULL,
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
CREATE INDEX "mapRegions_mapRegions_IX_region" ON "mapRegions" ("regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupRegion" ON "mapDenormalize" ("groupID","regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupConstellation" ON "mapDenormalize" ("groupID","constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupSystem" ON "mapDenormalize" ("groupID","solarSystemID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_system" ON "mapDenormalize" ("solarSystemID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_constellation" ON "mapDenormalize" ("constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_region" ON "mapDenormalize" ("regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_orbit" ON "mapDenormalize" ("orbitID");
CREATE INDEX "mapConstellations_mapConstellations_IX_region" ON "mapConstellations" ("regionID");
CREATE INDEX "invBlueprintTypes_blueprinttypes" ON "invBlueprintTypes" ("productTypeID","blueprintTypeID");
CREATE INDEX "invBlueprintTypes_ibt_pti" ON "invBlueprintTypes" ("productTypeID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_region" ON "mapSolarSystems" ("regionID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_constellation" ON "mapSolarSystems" ("constellationID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_security" ON "mapSolarSystems" ("security");
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
  dataID smallint(6) default NULL,
  PRIMARY KEY  ("attributeID")
);

CREATE TABLE dgmEffects (
"effectID"  smallint(6) NOT NULL,
"effectName"  TEXT(400),
"effectCategory"  smallint(6),
"preExpression"  smallint(6),
"postExpression"  smallint(6),
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
 "typeID"  SMALLINT(6) NOT NULL,
 "attributeID"  SMALLINT(6) NOT NULL,
 "value"  double default NULL,
 PRIMARY KEY ("typeID", "attributeID")
);

CREATE TABLE "dgmTypeEffects" (
"typeID"  SMALLINT(6) NOT NULL,
"effectID"  SMALLINT(6) NOT NULL,
"isDefault"  INTEGER,
PRIMARY KEY ("typeID", "effectID")
);

CREATE TABLE "invCategories" (
"categoryID"  SMALLINT(3) NOT NULL,
"categoryName"  TEXT(100),
"description"  TEXT(3000),
"published"  INTEGER,
"iconID" smallint(6) default NULL,
"categoryNameID" smallint(6) default NULL,
"dataID" smallint(6) default NULL,
PRIMARY KEY ("categoryID")
);

CREATE TABLE "invGroups" (
"groupID" SMALLINT(6) NOT NULL,
"categoryID"  SMALLINT(3),
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
  "typeID"  SMALLINT(6) NOT NULL,
  "groupID"  SMALLINT(6),
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
  "controlTowerTypeID" SMALLINT(6) NOT NULL,
  "resourceTypeID" SMALLINT(6) NOT NULL,
  "purpose" tinyint(4) default NULL,
  "quantity" int(11) default NULL,
  "minSecurityLevel" double default NULL,
  "factionID" int(11) default NULL,
  "wormholeClassID" INTEGER default NULL,
  PRIMARY KEY  ("controlTowerTypeID","resourceTypeID")
);



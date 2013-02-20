CREATE TABLE "crtCategories" (
  "categoryID" integer NOT NULL,
  "description" varchar(500) DEFAULT NULL,
  "categoryName" varchar(256) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);
CREATE TABLE "crtCertificates" (
  "certificateID" integer NOT NULL,
  "categoryID" integer DEFAULT NULL,
  "classID" integer DEFAULT NULL,
  "grade" integer DEFAULT NULL,
  "corpID" integer DEFAULT NULL,
  "iconID" integer DEFAULT NULL,
  "description" varchar(500) DEFAULT NULL,
  PRIMARY KEY ("certificateID")
);
CREATE TABLE "crtClasses" (
  "classID" integer NOT NULL,
  "description" varchar(500) DEFAULT NULL,
  "className" varchar(256) DEFAULT NULL,
  PRIMARY KEY ("classID")
);
CREATE TABLE "crtRecommendations" (
  "recommendationID" integer NOT NULL,
  "shipTypeID" integer DEFAULT NULL,
  "certificateID" integer DEFAULT NULL,
  "recommendationLevel" integer NOT NULL DEFAULT '0',
  PRIMARY KEY ("recommendationID")
);
CREATE TABLE "crtRelationships" (
  "relationshipID" integer NOT NULL,
  "parentID" integer DEFAULT NULL,
  "parentTypeID" integer DEFAULT NULL,
  "parentLevel" integer DEFAULT NULL,
  "childID" integer DEFAULT NULL,
  PRIMARY KEY ("relationshipID")
);
CREATE TABLE "dgmAttributeCategories" (
  "categoryID" integer NOT NULL,
  "categoryName" varchar(50) DEFAULT NULL,
  "categoryDescription" varchar(200) DEFAULT NULL,
  PRIMARY KEY ("categoryID")
);
CREATE TABLE "eveUnits" (
  "unitID" integer NOT NULL,
  "unitName" varchar(100) DEFAULT NULL,
  "displayName" varchar(50) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  PRIMARY KEY ("unitID")
);
CREATE TABLE "invBlueprintTypes" (
  "blueprintTypeID" integer NOT NULL,
  "parentBlueprintTypeID" integer DEFAULT NULL,
  "productTypeID" integer DEFAULT NULL,
  "productionTime" integer DEFAULT NULL,
  "techLevel" integer DEFAULT NULL,
  "researchProductivityTime" integer DEFAULT NULL,
  "researchMaterialTime" integer DEFAULT NULL,
  "researchCopyTime" integer DEFAULT NULL,
  "researchTechTime" integer DEFAULT NULL,
  "productivityModifier" integer DEFAULT NULL,
  "materialModifier" integer DEFAULT NULL,
  "wasteFactor" integer DEFAULT NULL,
  "maxProductionLimit" integer DEFAULT NULL,
  PRIMARY KEY ("blueprintTypeID")
);
CREATE TABLE "invControlTowerResourcePurposes" (
  "purpose" integer NOT NULL,
  "purposeText" varchar(100) DEFAULT NULL,
  PRIMARY KEY ("purpose")
);
CREATE TABLE "invMarketGroups" (
  "marketGroupID" integer NOT NULL,
  "parentGroupID" integer DEFAULT NULL,
  "marketGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(3000) DEFAULT NULL,
  "iconID" integer DEFAULT NULL,
  "hasTypes" integer DEFAULT NULL,
  PRIMARY KEY ("marketGroupID")
);
CREATE TABLE "invMetaGroups" (
  "metaGroupID" integer NOT NULL,
  "metaGroupName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "iconID" integer DEFAULT NULL,
  PRIMARY KEY ("metaGroupID")
);
CREATE TABLE "invMetaTypes" (
  "typeID" integer NOT NULL,
  "parentTypeID" integer DEFAULT NULL,
  "metaGroupID" integer DEFAULT NULL,
  PRIMARY KEY ("typeID")
);
CREATE TABLE "invTypeMaterials" (
  "typeID" integer NOT NULL,
  "materialTypeID" integer NOT NULL,
  "quantity" integer NOT NULL DEFAULT '0',
  PRIMARY KEY ("typeID","materialTypeID")
);

CREATE TABLE "mapConstellations" (
  "regionID" integer DEFAULT NULL,
  "constellationID" integer NOT NULL,
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
  "factionID" integer DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("constellationID")
);
CREATE TABLE "mapDenormalize" (
  "itemID" integer NOT NULL,
  "typeID" integer DEFAULT NULL,
  "groupID" integer DEFAULT NULL,
  "solarSystemID" integer DEFAULT NULL,
  "constellationID" integer DEFAULT NULL,
  "regionID" integer DEFAULT NULL,
  "orbitID" integer DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "itemName" varchar(100) DEFAULT NULL,
  "security" double DEFAULT NULL,
  "celestialIndex" integer DEFAULT NULL,
  "orbitIndex" integer DEFAULT NULL,
  PRIMARY KEY ("itemID")
);
CREATE TABLE "mapRegions" (
  "regionID" integer NOT NULL,
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
  "factionID" integer DEFAULT NULL,
  "radius" double DEFAULT NULL,
  PRIMARY KEY ("regionID")
);
CREATE TABLE "mapSolarSystems" (
  "regionID" integer DEFAULT NULL,
  "constellationID" integer DEFAULT NULL,
  "solarSystemID" integer NOT NULL,
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
  "border" integer DEFAULT NULL,
  "fringe" integer DEFAULT NULL,
  "corridor" integer DEFAULT NULL,
  "hub" integer DEFAULT NULL,
  "international" integer DEFAULT NULL,
  "regional" integer DEFAULT NULL,
  "constellation" integer DEFAULT NULL,
  "security" double DEFAULT NULL,
  "factionID" integer DEFAULT NULL,
  "radius" double DEFAULT NULL,
  "sunTypeID" integer DEFAULT NULL,
  "securityClass" varchar(2) DEFAULT NULL,
  PRIMARY KEY ("solarSystemID")
);
CREATE TABLE "ramActivities" (
  "activityID" integer NOT NULL,
  "activityName" varchar(100) DEFAULT NULL,
  "iconNo" varchar(5) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "published" integer DEFAULT NULL,
  PRIMARY KEY ("activityID")
);
CREATE TABLE "ramAssemblyLineTypes" (
  "assemblyLineTypeID" integer NOT NULL,
  "assemblyLineTypeName" varchar(100) DEFAULT NULL,
  "description" varchar(1000) DEFAULT NULL,
  "baseTimeMultiplier" double DEFAULT NULL,
  "baseMaterialMultiplier" double DEFAULT NULL,
  "volume" double DEFAULT NULL,
  "activityID" integer DEFAULT NULL,
  "minCostPerHour" double DEFAULT NULL,
  PRIMARY KEY ("assemblyLineTypeID")
);
CREATE TABLE "ramInstallationTypeContents" (
  "installationTypeID" integer NOT NULL,
  "assemblyLineTypeID" integer NOT NULL,
  "quantity" integer DEFAULT NULL,
  PRIMARY KEY ("installationTypeID","assemblyLineTypeID")
);

CREATE TABLE "ramTypeRequirements" (
  "typeID" integer NOT NULL,
  "activityID" integer NOT NULL,
  "requiredTypeID" integer NOT NULL,
  "quantity" integer DEFAULT NULL,
  "damagePerJob" double DEFAULT NULL,
  "recycle" integer DEFAULT NULL,
  PRIMARY KEY ("typeID","activityID","requiredTypeID")
);

CREATE TABLE "staStations" (
  "stationID" integer NOT NULL,
  "security" integer DEFAULT NULL,
  "dockingCostPerVolume" double DEFAULT NULL,
  "maxShipVolumeDockable" double DEFAULT NULL,
  "officeRentalCost" integer DEFAULT NULL,
  "operationID" integer DEFAULT NULL,
  "stationTypeID" integer DEFAULT NULL,
  "corporationID" integer DEFAULT NULL,
  "solarSystemID" integer DEFAULT NULL,
  "constellationID" integer DEFAULT NULL,
  "regionID" integer DEFAULT NULL,
  "stationName" varchar(100) DEFAULT NULL,
  "x" double DEFAULT NULL,
  "y" double DEFAULT NULL,
  "z" double DEFAULT NULL,
  "reprocessingEfficiency" double DEFAULT NULL,
  "reprocessingStationsTake" double DEFAULT NULL,
  "reprocessingHangarFlag" integer DEFAULT NULL,
  PRIMARY KEY ("stationID")
);
CREATE INDEX "staStations_staStations_IX_constellation" ON "staStations" ("constellationID");
CREATE INDEX "staStations_staStations_IX_corporation" ON "staStations" ("corporationID");
CREATE INDEX "staStations_staStations_IX_operation" ON "staStations" ("operationID");
CREATE INDEX "staStations_staStations_IX_region" ON "staStations" ("regionID");
CREATE INDEX "staStations_staStations_IX_system" ON "staStations" ("solarSystemID");
CREATE INDEX "staStations_staStations_IX_type" ON "staStations" ("stationTypeID");
CREATE INDEX "crtCertificates_crtCertificates_IX_category" ON "crtCertificates" ("categoryID");
CREATE INDEX "crtCertificates_crtCertificates_IX_class" ON "crtCertificates" ("classID");
CREATE INDEX "crtRelationships_crtRelationships_IX_child" ON "crtRelationships" ("childID");
CREATE INDEX "crtRelationships_crtRelationships_IX_parent" ON "crtRelationships" ("parentID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_constellation" ON "mapDenormalize" ("constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupConstell" ON "mapDenormalize" ("groupID","constellationID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupRegion" ON "mapDenormalize" ("groupID","regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_groupSystem" ON "mapDenormalize" ("groupID","solarSystemID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_orbit" ON "mapDenormalize" ("orbitID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_region" ON "mapDenormalize" ("regionID");
CREATE INDEX "mapDenormalize_mapDenormalize_IX_system" ON "mapDenormalize" ("solarSystemID");
CREATE INDEX "mapConstellations_mapConstellations_IX_region" ON "mapConstellations" ("regionID");
CREATE INDEX "crtRecommendations_crtRecommendations_IX_certifica" ON "crtRecommendations" ("certificateID");
CREATE INDEX "crtRecommendations_crtRecommendations_IX_shipType" ON "crtRecommendations" ("shipTypeID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_constellation" ON "mapSolarSystems" ("constellationID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_region" ON "mapSolarSystems" ("regionID");
CREATE INDEX "mapSolarSystems_mapSolarSystems_IX_security" ON "mapSolarSystems" ("security");
CREATE TABLE "eveIcons" (
  "iconID" integer NOT NULL,
  "iconFile" varchar(500) NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("iconID")
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


CREATE TABLE [crtCategories] (
	"categoryID"		smallint NOT NULL,
	"description"		nvarchar(500),
	"categoryName"		nvarchar(256),
    PRIMARY KEY ([categoryID])

);

CREATE TABLE [crtCertificates] (
	"certificateID"		integer NOT NULL,
	"categoryID"		smallint,
	"classID"		integer,
	"grade"		smallint,
	"corpID"		integer,
	"iconID"		integer,
	"description"		nvarchar(500),
    PRIMARY KEY ([certificateID])

);
CREATE TABLE [crtClasses] (
	"classID"		integer NOT NULL,
	"description"		nvarchar(500),
	"className"		nvarchar(256),
    PRIMARY KEY ([classID])

);
CREATE TABLE [crtRecommendations] (
	"recommendationID"		integer NOT NULL,
	"shipTypeID"		integer,
	"certificateID"		integer,
	"recommendationLevel"		smallint NOT NULL DEFAULT 0,
    PRIMARY KEY ([recommendationID])

);
CREATE TABLE [crtRelationships] (
	"relationshipID"		integer NOT NULL,
	"parentID"		integer,
	"parentTypeID"		integer,
	"parentLevel"		smallint,
	"childID"		integer,
    PRIMARY KEY ([relationshipID])

);
CREATE TABLE [dgmAttributeCategories] (
	"categoryID"		smallint NOT NULL,
	"categoryName"		nvarchar(50),
	"categoryDescription"		nvarchar(200),
    PRIMARY KEY ([categoryID])

);

CREATE TABLE [eveIcons] (
	"iconID"		integer NOT NULL,
	"iconFile"		varchar(500) NOT NULL DEFAULT '',
	"description"		nvarchar NOT NULL DEFAULT '',
    PRIMARY KEY ([iconID])

);
CREATE TABLE [eveUnits] (
	"unitID"		smallint NOT NULL,
	"unitName"		varchar(100),
	"displayName"		varchar(50),
	"description"		varchar(1000),
    PRIMARY KEY ([unitID])

);

CREATE TABLE [invControlTowerResourcePurposes] (
	"purpose"		smallint NOT NULL,
	"purposeText"		varchar(100),
    PRIMARY KEY ([purpose])

);

CREATE TABLE [invMarketGroups] (
	"marketGroupID"		integer NOT NULL,
	"parentGroupID"		integer,
	"marketGroupName"		nvarchar(100),
	"description"		nvarchar(3000),
	"iconID"		integer,
	"hasTypes"		bit,
    PRIMARY KEY ([marketGroupID])

);
CREATE TABLE [invMetaGroups] (
	"metaGroupID"		smallint NOT NULL,
	"metaGroupName"		nvarchar(100),
	"description"		nvarchar(1000),
	"iconID"		integer,
    PRIMARY KEY ([metaGroupID])

);

CREATE TABLE [invMetaTypes] (
	"typeID"		integer NOT NULL,
	"parentTypeID"		integer,
	"metaGroupID"		smallint,
    PRIMARY KEY ([typeID])

);
CREATE TABLE [mapConstellations] (
	"regionID"		integer,
	"constellationID"		integer NOT NULL,
	"constellationName"		nvarchar(100) COLLATE NOCASE,
	"x"		float,
	"y"		float,
	"z"		float,
	"xMin"		float,
	"xMax"		float,
	"yMin"		float,
	"yMax"		float,
	"zMin"		float,
	"zMax"		float,
	"factionID"		integer,
	"radius"		float,
    PRIMARY KEY ([constellationID])

);
CREATE TABLE [mapDenormalize] (
	"itemID"		integer NOT NULL,
	"typeID"		integer,
	"groupID"		integer,
	"solarSystemID"		integer,
	"constellationID"		integer,
	"regionID"		integer,
	"orbitID"		integer,
	"x"		float,
	"y"		float,
	"z"		float,
	"radius"		float,
	"itemName"		nvarchar(100),
	"security"		float,
	"celestialIndex"		smallint,
	"orbitIndex"		smallint,
    PRIMARY KEY ([itemID])

);
CREATE TABLE [mapRegions] (
	"regionID"		integer NOT NULL,
	"regionName"		nvarchar(100) COLLATE NOCASE,
	"x"		float,
	"y"		float,
	"z"		float,
	"xMin"		float,
	"xMax"		float,
	"yMin"		float,
	"yMax"		float,
	"zMin"		float,
	"zMax"		float,
	"factionID"		integer,
	"radius"		float,
    PRIMARY KEY ([regionID])

);
CREATE TABLE [mapSolarSystems] (
	"regionID"		integer,
	"constellationID"		integer,
	"solarSystemID"		integer NOT NULL,
	"solarSystemName"		nvarchar(100) COLLATE NOCASE,
	"x"		float,
	"y"		float,
	"z"		float,
	"xMin"		float,
	"xMax"		float,
	"yMin"		float,
	"yMax"		float,
	"zMin"		float,
	"zMax"		float,
	"luminosity"		float,
	"border"		bit,
	"fringe"		bit,
	"corridor"		bit,
	"hub"		bit,
	"international"		bit,
	"regional"		bit,
	"constellation"		bit,
	"security"		float,
	"factionID"		integer,
	"radius"		float,
	"sunTypeID"		integer,
	"securityClass"		varchar(2),
    PRIMARY KEY ([solarSystemID])

);
CREATE TABLE [ramActivities] (
	"activityID"		smallint NOT NULL,
	"activityName"		nvarchar(100),
	"iconNo"		varchar(5),
	"description"		nvarchar(1000),
	"published"		bit,
    PRIMARY KEY ([activityID])

);

CREATE TABLE [ramAssemblyLineTypes] (
	"assemblyLineTypeID"		smallint NOT NULL,
	"assemblyLineTypeName"		nvarchar(100),
	"description"		nvarchar(1000),
	"baseTimeMultiplier"		float,
	"baseMaterialMultiplier"		float,
	"volume"		float,
	"activityID"		smallint,
	"minCostPerHour"		float,
    PRIMARY KEY ([assemblyLineTypeID])

);

CREATE TABLE [ramInstallationTypeContents] (
	"installationTypeID"		integer NOT NULL,
	"assemblyLineTypeID"		smallint NOT NULL,
	"quantity"		smallint,
    PRIMARY KEY ([installationTypeID], [assemblyLineTypeID])

);

CREATE TABLE [staStations] (
	"stationID"		integer NOT NULL,
	"security"		smallint,
	"dockingCostPerVolume"		float,
	"maxShipVolumeDockable"		float,
	"officeRentalCost"		integer,
	"operationID"		smallint,
	"stationTypeID"		integer,
	"corporationID"		integer,
	"solarSystemID"		integer,
	"constellationID"		integer,
	"regionID"		integer,
	"stationName"		nvarchar(100) COLLATE NOCASE,
	"x"		float,
	"y"		float,
	"z"		float,
	"reprocessingEfficiency"		float,
	"reprocessingStationsTake"		float,
	"reprocessingHangarFlag"		smallint,
    PRIMARY KEY ([stationID])

);
CREATE INDEX [crtCertificates_crtCertificates_IX_category]
ON [crtCertificates]
([categoryID]);
CREATE INDEX [crtCertificates_crtCertificates_IX_class]
ON [crtCertificates]
([classID]);
CREATE INDEX [crtRecommendations_crtRecommendations_IX_certificate]
ON [crtRecommendations]
([certificateID]);
CREATE INDEX [crtRecommendations_crtRecommendations_IX_shipType]
ON [crtRecommendations]
([shipTypeID]);
CREATE INDEX [crtRelationships_crtRelationships_IX_child]
ON [crtRelationships]
([childID]);
CREATE INDEX [crtRelationships_crtRelationships_IX_parent]
ON [crtRelationships]
([parentID]);
CREATE INDEX [mapConstellations_mapConstellations_IX_region]
ON [mapConstellations]
([regionID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_constellation]
ON [mapDenormalize]
([constellationID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_groupConstellation]
ON [mapDenormalize]
([groupID], [constellationID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_groupRegion]
ON [mapDenormalize]
([groupID], [regionID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_groupSystem]
ON [mapDenormalize]
([groupID], [solarSystemID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_orbit]
ON [mapDenormalize]
([orbitID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_region]
ON [mapDenormalize]
([regionID]);
CREATE INDEX [mapDenormalize_mapDenormalize_IX_system]
ON [mapDenormalize]
([solarSystemID]);
CREATE INDEX [mapSolarSystems_mapSolarSystems_IX_constellation]
ON [mapSolarSystems]
([constellationID]);
CREATE INDEX [mapSolarSystems_mapSolarSystems_IX_region]
ON [mapSolarSystems]
([regionID]);
CREATE INDEX [mapSolarSystems_mapSolarSystems_IX_security]
ON [mapSolarSystems]
([security]);
CREATE INDEX [staStations_staStations_IX_constellation]
ON [staStations]
([constellationID]);
CREATE INDEX [staStations_staStations_IX_corporation]
ON [staStations]
([corporationID]);
CREATE INDEX [staStations_staStations_IX_operation]
ON [staStations]
([operationID]);
CREATE INDEX [staStations_staStations_IX_region]
ON [staStations]
([regionID]);
CREATE INDEX [staStations_staStations_IX_system]
ON [staStations]
([solarSystemID]);
CREATE INDEX [staStations_staStations_IX_type]
ON [staStations]
([stationTypeID]);
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


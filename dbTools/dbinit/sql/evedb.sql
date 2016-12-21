attach database "./tmp/evedb.sqlite" as eveDB;

--BEGIN TRANSACTION;

--INSERT INTO eveDB.invBlueprintTypes SELECT * FROM invBlueprintTypes;
INSERT INTO eveDB.invTypeMaterials SELECT * FROM invTypeMaterials;
INSERT INTO eveDB.dgmAttributeCategories SELECT * FROM dgmAttributeCategories;
--INSERT INTO eveDB.dgmTypeAttributes SELECT dgmTypeAttributes.* FROM dgmTypeAttributes,eveDB.invTypes WHERE dgmTypeAttributes.typeID=eveDB.invTypes.typeID;
--INSERT INTO eveDB.dgmTypeEffects SELECT dgmTypeEffects.* FROM dgmTypeEffects,eveDB.invTypes WHERE dgmTypeEffects.typeID=eveDB.invTypes.typeID;
--INSERT INTO eveDB.invMarketGroups SELECT * FROM invMarketGroups;
INSERT INTO eveDB.mapRegions SELECT * FROM mapRegions;
INSERT INTO eveDB.mapSolarSystems SELECT * FROM mapSolarSystems;
INSERT INTO eveDB.staStations SELECT * FROM staStations;
INSERT INTO eveDB.mapConstellations SELECT * FROM mapConstellations;
--INSERT INTO eveDB.eveIcons SELECT * FROM eveIcons;
INSERT INTO eveDB.eveUnits SELECT * FROM eveUnits;
INSERT INTO eveDB.ramActivities SELECT * FROM ramActivities;
INSERT INTO eveDB.mapDenormalize SELECT * FROM mapDenormalize WHERE groupID in (5,7,8,15);
INSERT INTO eveDB.invControlTowerResourcePurposes SELECT * FROM invControlTowerResourcePurposes;
INSERT INTO eveDB.invControlTowerResources SELECT * FROM invControlTowerResources;
INSERT INTO eveDB.invMetaGroups SELECT * FROM invMetaGroups;
INSERT INTO eveDB.invMetaTypes SELECT * FROM invMetaTypes;
INSERT INTO eveDB.invTraits SELECT * FROM invTraits;
INSERT INTO eveDB.certCerts SELECT * FROM certCerts;
INSERT INTO eveDB.certMasteries SELECT * FROM certMasteries;
INSERT INTO eveDB.certSkills SELECT * FROM certSkills;
INSERT INTO eveDB.ramAssemblyLineTypes SELECT * FROM ramAssemblyLineTypes;
INSERT INTO eveDB.ramInstallationTypeContents SELECT * FROM ramInstallationTypeContents;
--INSERT INTO eveDB.ramTypeRequirements SELECT * FROM ramTypeRequirements;
INSERT INTO eveDB.industryActivity SELECT * FROM industryActivity;
INSERT INTO eveDB.industryActivityMaterials SELECT * FROM industryActivityMaterials;
INSERT INTO eveDB.industryActivityProbabilities SELECT * FROM industryActivityProbabilities;
INSERT INTO eveDB.industryActivityProducts SELECT * FROM industryActivityProducts;
--INSERT INTO eveDB.industryActivityRaces SELECT * FROM industryActivityRaces;
INSERT INTO eveDB.industryActivitySkills SELECT * FROM industryActivitySkills;
INSERT INTO eveDB.industryBlueprints SELECT * FROM industryBlueprints;

INSERT INTO eveDB.chrRaces SELECT * FROM chrRaces;

--INSERT INTO eveDB.invTypes SELECT * FROM invTypes;
--INSERT INTO eveDB.invGroups SELECT * FROM invGroups;
--INSERT INTO eveDB.invCategories SELECT * FROM invCategories;
INSERT INTO eveDB.dgmEffects SELECT * FROM dgmEffects;
--INSERT INTO eveDB.dgmAttributeTypes SELECT * FROM dgmAttributeTypes;

delete from eveDB.invCategories where categoryID not in (2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,65,66,87,350001);
delete from eveDB.invGroups where categoryID not in (select categoryID from eveDB.invCategories);
delete from eveDB.invTypes where groupID not in (select groupID from eveDB.invGroups);

UPDATE eveDB.dgmAttributeTypes SET categoryID=9 WHERE categoryID is NULL or categoryID=0;

UPDATE eveDB.dgmAttributeTypes SET categoryID=4 WHERE attributeID IN (109,110,111,113);
UPDATE eveDB.dgmAttributeTypes SET categoryID=1 WHERE attributeID IN (1547,1132,1367);
UPDATE eveDB.dgmAttributeTypes SET iconID=1396 WHERE attributeID=974;
UPDATE eveDB.dgmAttributeTypes SET iconID=1395 WHERE attributeID=975;
UPDATE eveDB.dgmAttributeTypes SET iconID=1393 WHERE attributeID=976;
UPDATE eveDB.dgmAttributeTypes SET iconID=1394 WHERE attributeID=977;

UPDATE eveDB.dgmAttributeTypes SET published = 0 WHERE attributeName like "requiredSkill%Level";

UPDATE eveDB.invTypes SET published = 0 WHERE typeName like "%QA%";

INSERT INTO eveDB.invMetaTypes VALUES (29984,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29986,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29988,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29990,NULL,14);

INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 14 AS metaGroupID
		FROM eveDB.dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=3 AND a.typeID NOT IN (SELECT typeID FROM eveDB.invMetaTypes);


INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 1 AS metaGroupID
		FROM eveDB.dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=1 AND a.typeID NOT IN (SELECT typeID FROM eveDB.invMetaTypes);
		
INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 2 AS metaGroupID
		FROM eveDB.dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=2 AND a.typeID NOT IN (SELECT typeID FROM eveDB.invMetaTypes);
		
INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 1 AS metaGroupID
		FROM eveDB.dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=633 AND a.value=0 AND a.typeID NOT IN (SELECT typeID FROM eveDB.invMetaTypes);

CREATE INDEX eveDB.certCerts_groupID ON "certCerts" ("groupID" ASC);
CREATE INDEX eveDB.certMasteries_certID_typeID ON "certMasteries" ("certID" ASC, "typeID" ASC);
CREATE INDEX eveDB.certMasteries_typeID ON "certMasteries" ("typeID" ASC);
CREATE INDEX eveDB.certSkills_certID ON "certSkills" ("certID" ASC);
CREATE INDEX eveDB.invGroups_categoryID_published_groupName ON "invGroups" ("categoryID" ASC, "published" ASC, "groupName" ASC);
CREATE INDEX eveDB.invMarketGroups_parentGroupID_marketGroupName ON "invMarketGroups" ("parentGroupID" ASC, "marketGroupName" ASC);
CREATE INDEX eveDB.invMetaTypes_parentTypeID ON "invMetaTypes" ("parentTypeID" ASC);
CREATE INDEX eveDB.invTypes_groupID ON "invTypes" ("groupID" ASC);
CREATE INDEX eveDB.invTypes_marketGroupID ON "invTypes" ("marketGroupID" ASC);
CREATE INDEX eveDB.invTypes_typeName ON "invTypes" ("typeName" ASC);
CREATE INDEX eveDB.mapRegions_regionName ON "mapRegions" ("regionName" ASC);
CREATE INDEX eveDB.mapSolarSystems_regionID_solarSystemName ON "mapSolarSystems" ("regionID" ASC, "solarSystemName" ASC);
CREATE INDEX eveDB.mapSolarSystems_solarSystemName ON "mapSolarSystems" ("solarSystemName" ASC);
CREATE INDEX eveDB.invTraits_typeID ON "invTraits" ("typeID" ASC);

--Missing chargeSize
INSERT INTO eveDB.dgmTypeAttributes (typeID,attributeID,value) VALUES(263,128,0);
INSERT INTO eveDB.dgmTypeAttributes (typeID,attributeID,value) VALUES(33330,128,0);

--COMMIT TRANSACTION;

.read "./tmp/typesMap.sql"

--BEGIN TRANSACTION;

INSERT INTO eveDB.invBlueprintTypes SELECT * FROM invBlueprintTypes;
INSERT INTO eveDB.invCategories SELECT * FROM invCategories WHERE categoryID in (2,3,4,5,6,7,8,9,11,16,17,18,20,22,23,24,25,30,32,34,35,39,40,41,42,43,46,63,350001);
INSERT INTO eveDB.invGroups SELECT invGroups.* FROM invGroups,eveDB.invCategories WHERE invGroups.categoryID=eveDB.invCategories.categoryID;
INSERT INTO eveDB.invTypes SELECT invTypes.* FROM invTypes,eveDB.invGroups WHERE invTypes.groupID=eveDB.invGroups.groupID;
INSERT INTO eveDB.invTypeMaterials SELECT * FROM invTypeMaterials;
INSERT INTO eveDB.dgmAttributeCategories SELECT * FROM dgmAttributeCategories;
INSERT INTO eveDB.dgmEffects SELECT * FROM dgmEffects;
INSERT INTO eveDB.dgmAttributeTypes SELECT * FROM dgmAttributeTypes;
INSERT INTO eveDB.dgmTypeAttributes SELECT dgmTypeAttributes.* FROM dgmTypeAttributes,eveDB.invTypes WHERE dgmTypeAttributes.typeID=eveDB.invTypes.typeID;
INSERT INTO eveDB.dgmTypeEffects SELECT dgmTypeEffects.* FROM dgmTypeEffects,eveDB.invTypes WHERE dgmTypeEffects.typeID=eveDB.invTypes.typeID;
INSERT INTO eveDB.invMarketGroups SELECT * FROM invMarketGroups;
INSERT INTO eveDB.mapRegions SELECT * FROM mapRegions;
INSERT INTO eveDB.mapSolarSystems SELECT * FROM mapSolarSystems;
INSERT INTO eveDB.staStations SELECT * FROM staStations;
INSERT INTO eveDB.mapConstellations SELECT * FROM mapConstellations;
INSERT INTO eveDB.eveIcons SELECT * FROM eveIcons;
INSERT INTO eveDB.eveUnits SELECT * FROM eveUnits;
INSERT INTO eveDB.ramActivities SELECT * FROM ramActivities;
INSERT INTO eveDB.mapDenormalize SELECT * FROM mapDenormalize WHERE groupID in (5,7,8,15);
INSERT INTO eveDB.invControlTowerResourcePurposes SELECT * FROM invControlTowerResourcePurposes;
INSERT INTO eveDB.invControlTowerResources SELECT * FROM invControlTowerResources;
INSERT INTO eveDB.invMetaGroups SELECT * FROM invMetaGroups;
INSERT INTO eveDB.invMetaTypes SELECT * FROM invMetaTypes;
INSERT INTO eveDB.crtCategories SELECT * FROM crtCategories;
INSERT INTO eveDB.crtCertificates SELECT * FROM crtCertificates;
INSERT INTO eveDB.crtClasses SELECT * FROM crtClasses;
INSERT INTO eveDB.crtRecommendations SELECT * FROM crtRecommendations;
INSERT INTO eveDB.crtRelationships SELECT * FROM crtRelationships;
INSERT INTO eveDB.ramAssemblyLineTypes SELECT * FROM ramAssemblyLineTypes;
INSERT INTO eveDB.ramInstallationTypeContents SELECT * FROM ramInstallationTypeContents;
INSERT INTO eveDB.ramTypeRequirements SELECT * FROM ramTypeRequirements;


UPDATE eveDB.dgmAttributeTypes SET categoryID=9 WHERE categoryID is NULL or categoryID=0;

UPDATE eveDB.dgmAttributeTypes SET categoryID=4 WHERE attributeID IN (109,110,111,113);
UPDATE eveDB.dgmAttributeTypes SET categoryID=1 WHERE attributeID IN (1547,1132,1367);
UPDATE eveDB.dgmAttributeTypes SET iconID=1396 WHERE attributeID=974;
UPDATE eveDB.dgmAttributeTypes SET iconID=1395 WHERE attributeID=975;
UPDATE eveDB.dgmAttributeTypes SET iconID=1393 WHERE attributeID=976;
UPDATE eveDB.dgmAttributeTypes SET iconID=1394 WHERE attributeID=977;

INSERT INTO eveDB.invMetaTypes VALUES (29984,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29986,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29988,NULL,14);
INSERT INTO eveDB.invMetaTypes VALUES (29990,NULL,14);

INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 14 AS metaGroupID
		FROM dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=3 AND a.typeID NOT IN (SELECT typeID FROM invMetaTypes);


INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 1 AS metaGroupID
		FROM dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=1 AND a.typeID NOT IN (SELECT typeID FROM invMetaTypes);
		
INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 2 AS metaGroupID
		FROM dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=422 AND a.value=2 AND a.typeID NOT IN (SELECT typeID FROM invMetaTypes);
		
INSERT INTO eveDB.invMetaTypes
	SELECT a.typeID AS typeID, NULL AS parentTypeID, 1 AS metaGroupID
		FROM dgmTypeAttributes AS a, invTypes AS b
		WHERE a.typeID=b.typeID AND b.published = 1 AND b.marketGroupID IS NOT NULL AND b.marketGroupID > 0 AND a.attributeID=633 AND a.value=0 AND a.typeID NOT IN (SELECT typeID FROM invMetaTypes);


--COMMIT TRANSACTION;
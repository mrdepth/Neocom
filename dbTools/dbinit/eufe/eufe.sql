DROP TABLE IF EXISTS eufe.invGroups;
CREATE TABLE eufe.invGroups (
  "groupID" smallint(6) NOT NULL,
  "categoryID" tinyint(3) default NULL,
  "groupName" varchar(100) DEFAULT NULL,
  PRIMARY KEY  ("groupID")
);
DROP TABLE IF EXISTS eufe.invTypes;
CREATE TABLE eufe.invTypes (
  "typeID" int(11) NOT NULL,
  "groupID" smallint(6) default NULL,
  "typeName" varchar(100) default NULL,
  "radius" double default NULL,
  "mass" double default NULL,
  "volume" double default NULL,
  "capacity" double default NULL,
  "portionSize" int(11) default NULL,
  "raceID" tinyint(3) default NULL,
  "published" tinyint(1) default NULL,
  PRIMARY KEY  ("typeID")
);
DROP TABLE IF EXISTS eufe.dgmAttributeTypes;
CREATE TABLE eufe.dgmAttributeTypes (
  "attributeID" smallint(6) NOT NULL,
  "attributeName" varchar(100) default NULL,
  "maxAttributeID" smallint(6) default NULL,
  "defaultValue" double default NULL,
  "stackable" tinyint(1) default NULL,
  "highIsGood" tinyint(1) default NULL,
  "categoryID" tinyint(3) default NULL,
  PRIMARY KEY  ("attributeID")
);
DROP TABLE IF EXISTS eufe.dgmTypeAttributes;
CREATE TABLE eufe.dgmTypeAttributes (
  "typeID" smallint(6) NOT NULL,
  "attributeID" smallint(6) NOT NULL,
  "value" double default NULL,
  PRIMARY KEY  ("typeID","attributeID")
);
DROP TABLE IF EXISTS eufe.dgmTypeEffects;
CREATE TABLE eufe.dgmTypeEffects (
  "typeID" smallint(6) NOT NULL,
  "effectID" smallint(6) NOT NULL,
  "isDefault" tinyint(1) default NULL,
  PRIMARY KEY  ("typeID","effectID")
);
DROP TABLE IF EXISTS eufe.invCategories;
CREATE TABLE eufe.invCategories (
"categoryID"  tinyint(3) NOT NULL,
"categoryName"  TEXT(100),
"description"  TEXT(3000),
"published"  tinyint(1),
"iconID" smallint(6) default NULL,
"categoryNameID" smallint(6) default NULL,
"dataID" smallint(6) default NULL,
PRIMARY KEY ("categoryID")
);


INSERT INTO eufe.invGroups SELECT groupID, categoryID, groupName  FROM invGroups;
INSERT INTO eufe.invTypes SELECT typeID, groupID, typeName, radius, mass, volume, capacity, portionSize, raceID, published FROM invTypes;
INSERT INTO eufe.dgmAttributeTypes SELECT attributeID, attributeName, maxAttributeID, defaultValue, stackable, highIsGood, categoryID FROM dgmAttributeTypes;
INSERT INTO eufe.dgmTypeAttributes SELECT * FROM dgmTypeAttributes;
INSERT INTO eufe.dgmTypeEffects SELECT * FROM dgmTypeEffects;
INSERT INTO eufe.invCategories SELECT * FROM invCategories;

CREATE INDEX eufe.invGroups_categoryID ON "invGroups" ("categoryID" ASC);
CREATE INDEX eufe.invTypes_groupID_published ON "invTypes" ("groupID" ASC, "published" ASC);
CREATE INDEX eufe.invTypes_typeName ON "invTypes" ("typeName" ASC);
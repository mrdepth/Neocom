--Missing groupID fix
UPDATE dgmExpressions SET expressionGroupID=74 WHERE expressionID=663;
UPDATE dgmExpressions SET expressionGroupID=55 WHERE expressionID=649;
UPDATE dgmExpressions SET expressionGroupID=53 WHERE expressionID=658;
UPDATE dgmExpressions SET expressionGroupID=54 WHERE expressionID=641;
UPDATE dgmExpressions SET expressionGroupID=54 WHERE expressionID=641;

--Missing typeID fix
UPDATE dgmExpressions SET expressionTypeID=3422 WHERE expressionID=1728;
UPDATE dgmExpressions SET expressionTypeID=3423 WHERE expressionID=1555;
UPDATE dgmExpressions SET expressionTypeID=3452 WHERE expressionID=1506;

--Online effect fix
UPDATE dgmEffects SET preExpression=399 WHERE effectID=16;

--Character missileDamageMultiplier bonus fix
DELETE FROM "dgmExpressions" WHERE expressionID IN (20000, 20001, 20002, 20003, 20004, 20005, 20006, 20007);

INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20000,11,9943,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->emDamage).(PostMul)).AORSM(missileDamageMultiplier)',0,0,0);
INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20001,62,9943,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->emDamage).(PostMul)).RORSM(missileDamageMultiplier)',0,0,0);

INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20002,11,9952,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->kineticDamage).(PostMul)).AORSM(missileDamageMultiplier)',0,0,0);
INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20003,62,9952,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->kineticDamage).(PostMul)).RORSM(missileDamageMultiplier)',0,0,0);

INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20004,11,9949,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->thermalDamage).(PostMul)).AORSM(missileDamageMultiplier)',0,0,0);
INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20005,62,9949,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->thermalDamage).(PostMul)).RORSM(missileDamageMultiplier)',0,0,0);

INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20006,11,9946,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->explosiveDamage).(PostMul)).AORSM(missileDamageMultiplier)',0,0,0);
INSERT INTO "dgmExpressions" (expressionID,operandID,arg1,arg2,expressionValue,description,expressionName,expressionTypeID,expressionGroupID,expressionAttributeID)
 VALUES(20007,62,9946,717,NULL,'eufe: Character missileDamageMultiplier bonus','((CurrentChar[Missile Launcher Operation]->explosiveDamage).(PostMul)).RORSM(missileDamageMultiplier)',0,0,0);

DELETE FROM "dgmEffects" WHERE effectID IN (10000, 10001, 10002, 10003);

INSERT INTO "dgmEffects" (effectID,effectName,effectCategory,preExpression,postExpression,description,isOffensive,isAssistance)
 VALUES ("10000","characterDamageEmMissiles","0","20000","20001","eufe: Character missileDamageMultiplier bonus","0","0");
INSERT INTO "dgmEffects" (effectID,effectName,effectCategory,preExpression,postExpression,description,isOffensive,isAssistance)
 VALUES ("10001","characterDamageKineticMissiles","0","20002","20003","eufe: Character missileDamageMultiplier bonus","0","0");
INSERT INTO "dgmEffects" (effectID,effectName,effectCategory,preExpression,postExpression,description,isOffensive,isAssistance)
 VALUES ("10002","characterDamageThermalMissiles","0","20004","20005","eufe: Character missileDamageMultiplier bonus","0","0");
INSERT INTO "dgmEffects" (effectID,effectName,effectCategory,preExpression,postExpression,description,isOffensive,isAssistance)
 VALUES ("10003","characterDamageExplosiveMissiles","0","20006","20007","eufe: Character missileDamageMultiplier bonus","0","0");

DELETE FROM "dgmTypeEffects" WHERE effectID IN (10000, 10001, 10002, 10003);

INSERT INTO "dgmTypeEffects" VALUES ("1381","10000","0");
INSERT INTO "dgmTypeEffects" VALUES ("1381","10001","0");
INSERT INTO "dgmTypeEffects" VALUES ("1381","10002","0");
INSERT INTO "dgmTypeEffects" VALUES ("1381","10003","0");

--Warp Disruption Field Generator Fix
DELETE FROM "dgmTypeEffects" WHERE effectID=3461;

INSERT INTO "dgmTypeEffects" VALUES ("4248","3461","0");
INSERT INTO "dgmTypeEffects" VALUES ("28654","3461","0");

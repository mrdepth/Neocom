//
//  NCDBInvType.h
//  Neocom
//
//  Created by Артем Шиманский on 18.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBCertSkill, NCDBChrRace, NCDBDgmEffect, NCDBDgmTypeAttribute, NCDBEufeItem, NCDBEveIcon, NCDBInvBlueprintType, NCDBInvControlTower, NCDBInvControlTowerResource, NCDBInvGroup, NCDBInvMarketGroup, NCDBInvMetaGroup, NCDBInvType, NCDBInvTypeMaterial, NCDBInvTypeRequiredSkill, NCDBMapDenormalize, NCDBRamInstallationTypeContent, NCDBRamTypeRequirement, NCDBStaStation, NCDBTxtDescription;

@interface NCDBInvType : NSManagedObject

@property (nonatomic) float basePrice;
@property (nonatomic) float capacity;
@property (nonatomic) float mass;
@property (nonatomic, retain) NSString * metaGroupName;
@property (nonatomic) int16_t metaLevel;
@property (nonatomic) float portionSize;
@property (nonatomic) BOOL published;
@property (nonatomic) float radius;
@property (nonatomic) int32_t typeID;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic) float volume;
@property (nonatomic, retain) NSSet *attributes;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprint;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprintType;
@property (nonatomic, retain) NSSet *certificates;
@property (nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nonatomic, retain) NSSet *controlTowerResources;
@property (nonatomic, retain) NSSet *denormalize;
@property (nonatomic, retain) NSSet *effects;
@property (nonatomic, retain) NCDBInvGroup *group;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *installationTypeContents;
@property (nonatomic, retain) NCDBInvMarketGroup *marketGroup;
@property (nonatomic, retain) NSSet *masterySkills;
@property (nonatomic, retain) NCDBInvMetaGroup *metaGroup;
@property (nonatomic, retain) NCDBInvType *parentType;
@property (nonatomic, retain) NCDBChrRace *race;
@property (nonatomic, retain) NSSet *reguiredForSkill;
@property (nonatomic, retain) NSSet *requiredFor;
@property (nonatomic, retain) NSOrderedSet *requiredSkills;
@property (nonatomic, retain) NSSet *stations;
@property (nonatomic, retain) NCDBTxtDescription *typeDescription;
@property (nonatomic, retain) NSSet *typeMaterials;
@property (nonatomic, retain) NSSet *typeRequirements;
@property (nonatomic, retain) NSSet *variations;
@property (nonatomic, retain) NCDBEufeItem *eufeItem;
@end

@interface NCDBInvType (CoreDataGeneratedAccessors)

- (void)addAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)removeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)addAttributes:(NSSet *)values;
- (void)removeAttributes:(NSSet *)values;

- (void)addCertificatesObject:(NCDBCertCertificate *)value;
- (void)removeCertificatesObject:(NCDBCertCertificate *)value;
- (void)addCertificates:(NSSet *)values;
- (void)removeCertificates:(NSSet *)values;

- (void)addControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addControlTowerResources:(NSSet *)values;
- (void)removeControlTowerResources:(NSSet *)values;

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet *)values;
- (void)removeDenormalize:(NSSet *)values;

- (void)addEffectsObject:(NCDBDgmEffect *)value;
- (void)removeEffectsObject:(NCDBDgmEffect *)value;
- (void)addEffects:(NSSet *)values;
- (void)removeEffects:(NSSet *)values;

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet *)values;
- (void)removeInstallationTypeContents:(NSSet *)values;

- (void)addMasterySkillsObject:(NCDBCertSkill *)value;
- (void)removeMasterySkillsObject:(NCDBCertSkill *)value;
- (void)addMasterySkills:(NSSet *)values;
- (void)removeMasterySkills:(NSSet *)values;

- (void)addReguiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)removeReguiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)addReguiredForSkill:(NSSet *)values;
- (void)removeReguiredForSkill:(NSSet *)values;

- (void)addRequiredForObject:(NCDBRamTypeRequirement *)value;
- (void)removeRequiredForObject:(NCDBRamTypeRequirement *)value;
- (void)addRequiredFor:(NSSet *)values;
- (void)removeRequiredFor:(NSSet *)values;

- (void)insertObject:(NCDBInvTypeRequiredSkill *)value inRequiredSkillsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRequiredSkillsAtIndex:(NSUInteger)idx;
- (void)insertRequiredSkills:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRequiredSkillsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRequiredSkillsAtIndex:(NSUInteger)idx withObject:(NCDBInvTypeRequiredSkill *)value;
- (void)replaceRequiredSkillsAtIndexes:(NSIndexSet *)indexes withRequiredSkills:(NSArray *)values;
- (void)addRequiredSkillsObject:(NCDBInvTypeRequiredSkill *)value;
- (void)removeRequiredSkillsObject:(NCDBInvTypeRequiredSkill *)value;
- (void)addRequiredSkills:(NSOrderedSet *)values;
- (void)removeRequiredSkills:(NSOrderedSet *)values;
- (void)addStationsObject:(NCDBStaStation *)value;
- (void)removeStationsObject:(NCDBStaStation *)value;
- (void)addStations:(NSSet *)values;
- (void)removeStations:(NSSet *)values;

- (void)addTypeMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)removeTypeMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)addTypeMaterials:(NSSet *)values;
- (void)removeTypeMaterials:(NSSet *)values;

- (void)addTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)removeTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)addTypeRequirements:(NSSet *)values;
- (void)removeTypeRequirements:(NSSet *)values;

- (void)addVariationsObject:(NCDBInvType *)value;
- (void)removeVariationsObject:(NCDBInvType *)value;
- (void)addVariations:(NSSet *)values;
- (void)removeVariations:(NSSet *)values;

@end

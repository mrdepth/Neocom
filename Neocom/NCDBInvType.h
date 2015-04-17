//
//  NCDBInvType.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertCertificate, NCDBCertSkill, NCDBChrRace, NCDBDgmEffect, NCDBDgmTypeAttribute, NCDBEufeItem, NCDBEveIcon, NCDBIndBlueprintType, NCDBIndProduct, NCDBIndRequiredMaterial, NCDBIndRequiredSkill, NCDBInvControlTower, NCDBInvControlTowerResource, NCDBInvGroup, NCDBInvMarketGroup, NCDBInvMetaGroup, NCDBInvType, NCDBInvTypeRequiredSkill, NCDBMapDenormalize, NCDBRamInstallationTypeContent, NCDBStaStation, NCDBTxtDescription, NCDBWhType;

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
@property (nonatomic, retain) NCDBIndBlueprintType *blueprintType;
@property (nonatomic, retain) NSSet *certificates;
@property (nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nonatomic, retain) NSSet *controlTowerResources;
@property (nonatomic, retain) NSSet *denormalize;
@property (nonatomic, retain) NSSet *effects;
@property (nonatomic, retain) NCDBEufeItem *eufeItem;
@property (nonatomic, retain) NCDBInvGroup *group;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NSSet *indRequiredSkills;
@property (nonatomic, retain) NSSet *installationTypeContents;
@property (nonatomic, retain) NCDBInvMarketGroup *marketGroup;
@property (nonatomic, retain) NSSet *masterySkills;
@property (nonatomic, retain) NSSet *materials;
@property (nonatomic, retain) NCDBInvMetaGroup *metaGroup;
@property (nonatomic, retain) NCDBInvType *parentType;
@property (nonatomic, retain) NSSet *products;
@property (nonatomic, retain) NCDBChrRace *race;
@property (nonatomic, retain) NSSet *requiredForSkill;
@property (nonatomic, retain) NSOrderedSet *requiredSkills;
@property (nonatomic, retain) NSSet *stations;
@property (nonatomic, retain) NCDBTxtDescription *typeDescription;
@property (nonatomic, retain) NSSet *variations;
@property (nonatomic, retain) NCDBWhType* wormhole;
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

- (void)addIndRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)removeIndRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)addIndRequiredSkills:(NSSet *)values;
- (void)removeIndRequiredSkills:(NSSet *)values;

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet *)values;
- (void)removeInstallationTypeContents:(NSSet *)values;

- (void)addMasterySkillsObject:(NCDBCertSkill *)value;
- (void)removeMasterySkillsObject:(NCDBCertSkill *)value;
- (void)addMasterySkills:(NSSet *)values;
- (void)removeMasterySkills:(NSSet *)values;

- (void)addMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)removeMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)addMaterials:(NSSet *)values;
- (void)removeMaterials:(NSSet *)values;

- (void)addProductsObject:(NCDBIndProduct *)value;
- (void)removeProductsObject:(NCDBIndProduct *)value;
- (void)addProducts:(NSSet *)values;
- (void)removeProducts:(NSSet *)values;

- (void)addRequiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)removeRequiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)addRequiredForSkill:(NSSet *)values;
- (void)removeRequiredForSkill:(NSSet *)values;

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

- (void)addVariationsObject:(NCDBInvType *)value;
- (void)removeVariationsObject:(NCDBInvType *)value;
- (void)addVariations:(NSSet *)values;
- (void)removeVariations:(NSSet *)values;

@end

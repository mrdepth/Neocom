//
//  NCDBInvType+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvType (CoreDataProperties)

@property (nonatomic) float basePrice;
@property (nonatomic) float capacity;
@property (nonatomic) float mass;
@property (nullable, nonatomic, retain) NSString *metaGroupName;
@property (nonatomic) int16_t metaLevel;
@property (nonatomic) float portionSize;
@property (nonatomic) BOOL published;
@property (nonatomic) float radius;
@property (nonatomic) int32_t typeID;
@property (nullable, nonatomic, retain) NSString *typeName;
@property (nonatomic) float volume;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmTypeAttribute *> *attributes;
@property (nullable, nonatomic, retain) NCDBIndBlueprintType *blueprintType;
@property (nullable, nonatomic, retain) NSSet<NCDBCertCertificate *> *certificates;
@property (nullable, nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nullable, nonatomic, retain) NSSet<NCDBInvControlTowerResource *> *controlTowerResources;
@property (nullable, nonatomic, retain) NSSet<NCDBMapDenormalize *> *denormalize;
@property (nullable, nonatomic, retain) NSSet<NCDBDgmEffect *> *effects;
@property (nullable, nonatomic, retain) NCDBEufeItem *eufeItem;
@property (nullable, nonatomic, retain) NCDBInvGroup *group;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBIndRequiredSkill *> *indRequiredSkills;
@property (nullable, nonatomic, retain) NSSet<NCDBRamInstallationTypeContent *> *installationTypeContents;
@property (nullable, nonatomic, retain) NCDBInvMarketGroup *marketGroup;
@property (nullable, nonatomic, retain) NSSet<NCDBCertSkill *> *masterySkills;
@property (nullable, nonatomic, retain) NSSet<NCDBIndRequiredMaterial *> *materials;
@property (nullable, nonatomic, retain) NCDBInvMetaGroup *metaGroup;
@property (nullable, nonatomic, retain) NCDBInvType *parentType;
@property (nullable, nonatomic, retain) NSSet<NCDBIndProduct *> *products;
@property (nullable, nonatomic, retain) NCDBChrRace *race;
@property (nullable, nonatomic, retain) NSSet<NCDBInvTypeRequiredSkill *> *requiredForSkill;
@property (nullable, nonatomic, retain) NSOrderedSet<NCDBInvTypeRequiredSkill *> *requiredSkills;
@property (nullable, nonatomic, retain) NSSet<NCDBStaStation *> *stations;
@property (nullable, nonatomic, retain) NCDBTxtDescription *typeDescription;
@property (nullable, nonatomic, retain) NSSet<NCDBInvType *> *variations;
@property (nullable, nonatomic, retain) NCDBWhType *wormhole;
@property (nullable, nonatomic, retain) NCDBEufeHullType *hullType;

@end

@interface NCDBInvType (CoreDataGeneratedAccessors)

- (void)addAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)removeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)addAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;
- (void)removeAttributes:(NSSet<NCDBDgmTypeAttribute *> *)values;

- (void)addCertificatesObject:(NCDBCertCertificate *)value;
- (void)removeCertificatesObject:(NCDBCertCertificate *)value;
- (void)addCertificates:(NSSet<NCDBCertCertificate *> *)values;
- (void)removeCertificates:(NSSet<NCDBCertCertificate *> *)values;

- (void)addControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)removeControlTowerResourcesObject:(NCDBInvControlTowerResource *)value;
- (void)addControlTowerResources:(NSSet<NCDBInvControlTowerResource *> *)values;
- (void)removeControlTowerResources:(NSSet<NCDBInvControlTowerResource *> *)values;

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet<NCDBMapDenormalize *> *)values;
- (void)removeDenormalize:(NSSet<NCDBMapDenormalize *> *)values;

- (void)addEffectsObject:(NCDBDgmEffect *)value;
- (void)removeEffectsObject:(NCDBDgmEffect *)value;
- (void)addEffects:(NSSet<NCDBDgmEffect *> *)values;
- (void)removeEffects:(NSSet<NCDBDgmEffect *> *)values;

- (void)addIndRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)removeIndRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)addIndRequiredSkills:(NSSet<NCDBIndRequiredSkill *> *)values;
- (void)removeIndRequiredSkills:(NSSet<NCDBIndRequiredSkill *> *)values;

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet<NCDBRamInstallationTypeContent *> *)values;
- (void)removeInstallationTypeContents:(NSSet<NCDBRamInstallationTypeContent *> *)values;

- (void)addMasterySkillsObject:(NCDBCertSkill *)value;
- (void)removeMasterySkillsObject:(NCDBCertSkill *)value;
- (void)addMasterySkills:(NSSet<NCDBCertSkill *> *)values;
- (void)removeMasterySkills:(NSSet<NCDBCertSkill *> *)values;

- (void)addMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)removeMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)addMaterials:(NSSet<NCDBIndRequiredMaterial *> *)values;
- (void)removeMaterials:(NSSet<NCDBIndRequiredMaterial *> *)values;

- (void)addProductsObject:(NCDBIndProduct *)value;
- (void)removeProductsObject:(NCDBIndProduct *)value;
- (void)addProducts:(NSSet<NCDBIndProduct *> *)values;
- (void)removeProducts:(NSSet<NCDBIndProduct *> *)values;

- (void)addRequiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)removeRequiredForSkillObject:(NCDBInvTypeRequiredSkill *)value;
- (void)addRequiredForSkill:(NSSet<NCDBInvTypeRequiredSkill *> *)values;
- (void)removeRequiredForSkill:(NSSet<NCDBInvTypeRequiredSkill *> *)values;

- (void)insertObject:(NCDBInvTypeRequiredSkill *)value inRequiredSkillsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRequiredSkillsAtIndex:(NSUInteger)idx;
- (void)insertRequiredSkills:(NSArray<NCDBInvTypeRequiredSkill *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRequiredSkillsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRequiredSkillsAtIndex:(NSUInteger)idx withObject:(NCDBInvTypeRequiredSkill *)value;
- (void)replaceRequiredSkillsAtIndexes:(NSIndexSet *)indexes withRequiredSkills:(NSArray<NCDBInvTypeRequiredSkill *> *)values;
- (void)addRequiredSkillsObject:(NCDBInvTypeRequiredSkill *)value;
- (void)removeRequiredSkillsObject:(NCDBInvTypeRequiredSkill *)value;
- (void)addRequiredSkills:(NSOrderedSet<NCDBInvTypeRequiredSkill *> *)values;
- (void)removeRequiredSkills:(NSOrderedSet<NCDBInvTypeRequiredSkill *> *)values;

- (void)addStationsObject:(NCDBStaStation *)value;
- (void)removeStationsObject:(NCDBStaStation *)value;
- (void)addStations:(NSSet<NCDBStaStation *> *)values;
- (void)removeStations:(NSSet<NCDBStaStation *> *)values;

- (void)addVariationsObject:(NCDBInvType *)value;
- (void)removeVariationsObject:(NCDBInvType *)value;
- (void)addVariations:(NSSet<NCDBInvType *> *)values;
- (void)removeVariations:(NSSet<NCDBInvType *> *)values;

@end

NS_ASSUME_NONNULL_END

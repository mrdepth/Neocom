//
//  NCDBInvType.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBCertSkill, NCDBChrRace, NCDBDgmEffect, NCDBDgmTypeAttribute, NCDBEveIcon, NCDBInvBlueprintType, NCDBInvControlTower, NCDBInvControlTowerResource, NCDBInvGroup, NCDBInvMarketGroup, NCDBInvMetaType, NCDBInvTypeMaterial, NCDBMapDenormalize, NCDBRamInstallationTypeContent, NCDBRamTypeRequirement, NCDBStaStation;

@interface NCDBInvType : NSManagedObject

@property (nonatomic) float basePrice;
@property (nonatomic) float capacity;
@property (nonatomic) float mass;
@property (nonatomic) float portionSize;
@property (nonatomic) BOOL published;
@property (nonatomic) float radius;
@property (nonatomic) int32_t typeID;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic) float volume;
@property (nonatomic, retain) NSSet *attributes;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprint;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprintType;
@property (nonatomic, retain) NCDBInvControlTower *controlTower;
@property (nonatomic, retain) NSSet *controlTowerResources;
@property (nonatomic, retain) NSSet *denormalize;
@property (nonatomic, retain) NSSet *effects;
@property (nonatomic, retain) NCDBInvGroup *group;
@property (nonatomic, retain) NCDBEveIcon *icon;
@property (nonatomic, retain) NCDBInvMarketGroup *marketGroup;
@property (nonatomic, retain) NCDBInvMetaType *metaType;
@property (nonatomic, retain) NCDBChrRace *race;
@property (nonatomic, retain) NSSet *typeMaterials;
@property (nonatomic, retain) NSSet *variations;
@property (nonatomic, retain) NSSet *masterySkills;
@property (nonatomic, retain) NSSet *masteries;
@property (nonatomic, retain) NSSet *installationTypeContents;
@property (nonatomic, retain) NSSet *typeRequirements;
@property (nonatomic, retain) NSSet *requiredFor;
@property (nonatomic, retain) NSSet *stations;
@end

@interface NCDBInvType (CoreDataGeneratedAccessors)

- (void)addAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)removeAttributesObject:(NCDBDgmTypeAttribute *)value;
- (void)addAttributes:(NSSet *)values;
- (void)removeAttributes:(NSSet *)values;

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

- (void)addTypeMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)removeTypeMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)addTypeMaterials:(NSSet *)values;
- (void)removeTypeMaterials:(NSSet *)values;

- (void)addVariationsObject:(NCDBInvMetaType *)value;
- (void)removeVariationsObject:(NCDBInvMetaType *)value;
- (void)addVariations:(NSSet *)values;
- (void)removeVariations:(NSSet *)values;

- (void)addMasterySkillsObject:(NCDBCertSkill *)value;
- (void)removeMasterySkillsObject:(NCDBCertSkill *)value;
- (void)addMasterySkills:(NSSet *)values;
- (void)removeMasterySkills:(NSSet *)values;

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet *)values;
- (void)removeInstallationTypeContents:(NSSet *)values;

- (void)addTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)removeTypeRequirementsObject:(NCDBRamTypeRequirement *)value;
- (void)addTypeRequirements:(NSSet *)values;
- (void)removeTypeRequirements:(NSSet *)values;

- (void)addRequiredForObject:(NCDBRamTypeRequirement *)value;
- (void)removeRequiredForObject:(NCDBRamTypeRequirement *)value;
- (void)addRequiredFor:(NSSet *)values;
- (void)removeRequiredFor:(NSSet *)values;

- (void)addStationsObject:(NCDBStaStation *)value;
- (void)removeStationsObject:(NCDBStaStation *)value;
- (void)addStations:(NSSet *)values;
- (void)removeStations:(NSSet *)values;

@end

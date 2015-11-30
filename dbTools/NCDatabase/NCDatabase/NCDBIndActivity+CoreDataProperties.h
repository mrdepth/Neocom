//
//  NCDBIndActivity+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBIndActivity.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndActivity (CoreDataProperties)

@property (nonatomic) int32_t time;
@property (nullable, nonatomic, retain) NCDBRamActivity *activity;
@property (nullable, nonatomic, retain) NCDBIndBlueprintType *blueprintType;
@property (nullable, nonatomic, retain) NSSet<NCDBIndProduct *> *products;
@property (nullable, nonatomic, retain) NSSet<NCDBIndRequiredMaterial *> *requiredMaterials;
@property (nullable, nonatomic, retain) NSSet<NCDBIndRequiredSkill *> *requiredSkills;

@end

@interface NCDBIndActivity (CoreDataGeneratedAccessors)

- (void)addProductsObject:(NCDBIndProduct *)value;
- (void)removeProductsObject:(NCDBIndProduct *)value;
- (void)addProducts:(NSSet<NCDBIndProduct *> *)values;
- (void)removeProducts:(NSSet<NCDBIndProduct *> *)values;

- (void)addRequiredMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)removeRequiredMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)addRequiredMaterials:(NSSet<NCDBIndRequiredMaterial *> *)values;
- (void)removeRequiredMaterials:(NSSet<NCDBIndRequiredMaterial *> *)values;

- (void)addRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)removeRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)addRequiredSkills:(NSSet<NCDBIndRequiredSkill *> *)values;
- (void)removeRequiredSkills:(NSSet<NCDBIndRequiredSkill *> *)values;

@end

NS_ASSUME_NONNULL_END

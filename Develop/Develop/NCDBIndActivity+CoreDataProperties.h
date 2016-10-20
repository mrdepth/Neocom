//
//  NCDBIndActivity+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBIndActivity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndActivity (CoreDataProperties)

+ (NSFetchRequest<NCDBIndActivity *> *)fetchRequest;

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

//
//  NCDBIndActivity.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndBlueprintType, NCDBIndProduct, NCDBIndRequiredMaterial, NCDBIndRequiredSkill, NCDBRamActivity;

@interface NCDBIndActivity : NSManagedObject

@property (nonatomic) int32_t time;
@property (nonatomic, retain) NCDBRamActivity *activity;
@property (nonatomic, retain) NCDBIndBlueprintType *blueprintType;
@property (nonatomic, retain) NSSet *products;
@property (nonatomic, retain) NSSet *requiredMaterials;
@property (nonatomic, retain) NSSet *requiredSkills;
@end

@interface NCDBIndActivity (CoreDataGeneratedAccessors)

- (void)addProductsObject:(NCDBIndProduct *)value;
- (void)removeProductsObject:(NCDBIndProduct *)value;
- (void)addProducts:(NSSet *)values;
- (void)removeProducts:(NSSet *)values;

- (void)addRequiredMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)removeRequiredMaterialsObject:(NCDBIndRequiredMaterial *)value;
- (void)addRequiredMaterials:(NSSet *)values;
- (void)removeRequiredMaterials:(NSSet *)values;

- (void)addRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)removeRequiredSkillsObject:(NCDBIndRequiredSkill *)value;
- (void)addRequiredSkills:(NSSet *)values;
- (void)removeRequiredSkills:(NSSet *)values;

@end

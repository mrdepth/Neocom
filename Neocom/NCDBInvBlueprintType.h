//
//  NCDBInvBlueprintType.h
//  Neocom
//
//  Created by Shimanski Artem on 15.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvType, NCDBInvTypeMaterial;

@interface NCDBInvBlueprintType : NSManagedObject

@property (nonatomic) int32_t materialModifier;
@property (nonatomic) int32_t maxProductionLimit;
@property (nonatomic) int32_t productionTime;
@property (nonatomic) int32_t productivityModifier;
@property (nonatomic) int32_t researchCopyTime;
@property (nonatomic) int32_t researchMaterialTime;
@property (nonatomic) int32_t researchProductivityTime;
@property (nonatomic) int32_t researchTechTime;
@property (nonatomic) int16_t techLevel;
@property (nonatomic) int32_t wasteFactor;
@property (nonatomic, retain) NCDBInvType *blueprintType;
@property (nonatomic, retain) NSSet *materials;
@property (nonatomic, retain) NCDBInvType *productType;
@end

@interface NCDBInvBlueprintType (CoreDataGeneratedAccessors)

- (void)addMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)removeMaterialsObject:(NCDBInvTypeMaterial *)value;
- (void)addMaterials:(NSSet *)values;
- (void)removeMaterials:(NSSet *)values;

@end

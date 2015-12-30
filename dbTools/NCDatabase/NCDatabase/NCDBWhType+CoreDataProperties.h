//
//  NCDBWhType+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBWhType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBWhType (CoreDataProperties)

@property (nonatomic) float maxJumpMass;
@property (nonatomic) float maxRegeneration;
@property (nonatomic) float maxStableMass;
@property (nonatomic) float maxStableTime;
@property (nonatomic) int32_t targetSystemClass;
@property (nullable, nonatomic, retain) NSString *targetSystemClassDisplayName;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END

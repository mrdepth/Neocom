//
//  NCDBWhType+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBWhType+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBWhType (CoreDataProperties)

+ (NSFetchRequest<NCDBWhType *> *)fetchRequest;

@property (nonatomic) float maxJumpMass;
@property (nonatomic) float maxRegeneration;
@property (nonatomic) float maxStableMass;
@property (nonatomic) float maxStableTime;
@property (nonatomic) int32_t targetSystemClass;
@property (nullable, nonatomic, copy) NSString *targetSystemClassDisplayName;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END

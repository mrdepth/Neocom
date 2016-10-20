//
//  NCDBWhType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBWhType+CoreDataProperties.h"

@implementation NCDBWhType (CoreDataProperties)

+ (NSFetchRequest<NCDBWhType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WhType"];
}

@dynamic maxJumpMass;
@dynamic maxRegeneration;
@dynamic maxStableMass;
@dynamic maxStableTime;
@dynamic targetSystemClass;
@dynamic targetSystemClassDisplayName;
@dynamic type;

@end

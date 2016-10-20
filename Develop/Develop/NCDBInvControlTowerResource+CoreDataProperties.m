//
//  NCDBInvControlTowerResource+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTowerResource+CoreDataProperties.h"

@implementation NCDBInvControlTowerResource (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTowerResource *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvControlTowerResource"];
}

@dynamic factionID;
@dynamic minSecurityLevel;
@dynamic quantity;
@dynamic wormholeClassID;
@dynamic controlTower;
@dynamic purpose;
@dynamic resourceType;

@end

//
//  NCDBDgmppItemShipResources+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemShipResources+CoreDataProperties.h"

@implementation NCDBDgmppItemShipResources (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemShipResources *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemShipResources"];
}

@dynamic hiSlots;
@dynamic launchers;
@dynamic lowSlots;
@dynamic medSlots;
@dynamic rigSlots;
@dynamic turrets;
@dynamic item;

@end

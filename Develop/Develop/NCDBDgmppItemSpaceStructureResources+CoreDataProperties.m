//
//  NCDBDgmppItemSpaceStructureResources+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemSpaceStructureResources+CoreDataProperties.h"

@implementation NCDBDgmppItemSpaceStructureResources (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemSpaceStructureResources *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemSpaceStructureResources"];
}

@dynamic hiSlots;
@dynamic launchers;
@dynamic lowSlots;
@dynamic medSlots;
@dynamic rigSlots;
@dynamic serviceSlots;
@dynamic turrets;
@dynamic item;

@end

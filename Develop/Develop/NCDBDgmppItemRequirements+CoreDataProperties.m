//
//  NCDBDgmppItemRequirements+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemRequirements+CoreDataProperties.h"

@implementation NCDBDgmppItemRequirements (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemRequirements *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemRequirements"];
}

@dynamic calibration;
@dynamic cpu;
@dynamic powerGrid;
@dynamic item;

@end

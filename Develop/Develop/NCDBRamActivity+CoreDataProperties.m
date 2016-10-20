//
//  NCDBRamActivity+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamActivity+CoreDataProperties.h"

@implementation NCDBRamActivity (CoreDataProperties)

+ (NSFetchRequest<NCDBRamActivity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RamActivity"];
}

@dynamic activityID;
@dynamic activityName;
@dynamic published;
@dynamic assemblyLineTypes;
@dynamic icon;
@dynamic indActivities;

@end

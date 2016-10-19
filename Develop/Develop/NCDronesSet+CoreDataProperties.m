//
//  NCDronesSet+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDronesSet+CoreDataProperties.h"

@implementation NCDronesSet (CoreDataProperties)

+ (NSFetchRequest<NCDronesSet *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DronesSet"];
}

@dynamic data;
@dynamic name;

@end

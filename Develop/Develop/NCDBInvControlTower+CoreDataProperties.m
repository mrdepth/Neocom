//
//  NCDBInvControlTower+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvControlTower+CoreDataProperties.h"

@implementation NCDBInvControlTower (CoreDataProperties)

+ (NSFetchRequest<NCDBInvControlTower *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvControlTower"];
}

@dynamic resources;
@dynamic type;

@end

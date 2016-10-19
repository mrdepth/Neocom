//
//  NCLoadout+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLoadout+CoreDataProperties.h"

@implementation NCLoadout (CoreDataProperties)

+ (NSFetchRequest<NCLoadout *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Loadout"];
}

@dynamic name;
@dynamic tag;
@dynamic typeID;
@dynamic url;
@dynamic data;

@end

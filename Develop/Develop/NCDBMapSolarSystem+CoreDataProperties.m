//
//  NCDBMapSolarSystem+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapSolarSystem+CoreDataProperties.h"

@implementation NCDBMapSolarSystem (CoreDataProperties)

+ (NSFetchRequest<NCDBMapSolarSystem *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MapSolarSystem"];
}

@dynamic factionID;
@dynamic security;
@dynamic solarSystemID;
@dynamic solarSystemName;
@dynamic constellation;
@dynamic denormalize;
@dynamic stations;

@end

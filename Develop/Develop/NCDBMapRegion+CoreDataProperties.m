//
//  NCDBMapRegion+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapRegion+CoreDataProperties.h"

@implementation NCDBMapRegion (CoreDataProperties)

+ (NSFetchRequest<NCDBMapRegion *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MapRegion"];
}

@dynamic factionID;
@dynamic regionID;
@dynamic regionName;
@dynamic constellations;
@dynamic denormalize;

@end

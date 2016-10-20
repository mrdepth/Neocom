//
//  NCDBMapConstellation+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapConstellation+CoreDataProperties.h"

@implementation NCDBMapConstellation (CoreDataProperties)

+ (NSFetchRequest<NCDBMapConstellation *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MapConstellation"];
}

@dynamic constellationID;
@dynamic constellationName;
@dynamic factionID;
@dynamic denormalize;
@dynamic region;
@dynamic solarSystems;

@end

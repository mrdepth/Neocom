//
//  NCDBStaStation+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBStaStation+CoreDataProperties.h"

@implementation NCDBStaStation (CoreDataProperties)

+ (NSFetchRequest<NCDBStaStation *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"StaStation"];
}

@dynamic security;
@dynamic stationID;
@dynamic stationName;
@dynamic solarSystem;
@dynamic stationType;

@end

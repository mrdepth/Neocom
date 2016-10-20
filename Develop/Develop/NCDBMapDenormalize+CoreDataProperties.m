//
//  NCDBMapDenormalize+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBMapDenormalize+CoreDataProperties.h"

@implementation NCDBMapDenormalize (CoreDataProperties)

+ (NSFetchRequest<NCDBMapDenormalize *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MapDenormalize"];
}

@dynamic itemID;
@dynamic itemName;
@dynamic security;
@dynamic constellation;
@dynamic region;
@dynamic solarSystem;
@dynamic type;

@end

//
//  NCDamagePattern+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDamagePattern+CoreDataProperties.h"

@implementation NCDamagePattern (CoreDataProperties)

+ (NSFetchRequest<NCDamagePattern *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DamagePattern"];
}

@dynamic em;
@dynamic explosive;
@dynamic kinetic;
@dynamic name;
@dynamic thermal;

@end

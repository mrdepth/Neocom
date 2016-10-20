//
//  NCDBDgmppItemDamage+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemDamage+CoreDataProperties.h"

@implementation NCDBDgmppItemDamage (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemDamage *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemDamage"];
}

@dynamic emAmount;
@dynamic explosiveAmount;
@dynamic kineticAmount;
@dynamic thermalAmount;
@dynamic item;

@end

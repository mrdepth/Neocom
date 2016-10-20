//
//  NCDBDgmppHullType+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppHullType+CoreDataProperties.h"

@implementation NCDBDgmppHullType (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppHullType *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppHullType"];
}

@dynamic hullTypeName;
@dynamic signature;
@dynamic types;

@end

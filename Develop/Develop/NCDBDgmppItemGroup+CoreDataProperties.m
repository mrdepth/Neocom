//
//  NCDBDgmppItemGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemGroup+CoreDataProperties.h"

@implementation NCDBDgmppItemGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemGroup"];
}

@dynamic groupName;
@dynamic category;
@dynamic icon;
@dynamic items;
@dynamic parentGroup;
@dynamic subGroups;

@end

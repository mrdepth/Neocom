//
//  NCDBDgmppItemCategory+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItemCategory+CoreDataProperties.h"

@implementation NCDBDgmppItemCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItemCategory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItemCategory"];
}

@dynamic category;
@dynamic subcategory;
@dynamic dgmppItems;
@dynamic itemGroups;
@dynamic race;

@end

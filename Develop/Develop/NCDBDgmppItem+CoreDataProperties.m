//
//  NCDBDgmppItem+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBDgmppItem+CoreDataProperties.h"

@implementation NCDBDgmppItem (CoreDataProperties)

+ (NSFetchRequest<NCDBDgmppItem *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DgmppItem"];
}

@dynamic charge;
@dynamic damage;
@dynamic groups;
@dynamic requirements;
@dynamic shipResources;
@dynamic spaceStructureResources;
@dynamic type;

@end

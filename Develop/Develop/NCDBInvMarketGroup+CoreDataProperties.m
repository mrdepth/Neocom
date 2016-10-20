//
//  NCDBInvMarketGroup+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvMarketGroup+CoreDataProperties.h"

@implementation NCDBInvMarketGroup (CoreDataProperties)

+ (NSFetchRequest<NCDBInvMarketGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvMarketGroup"];
}

@dynamic marketGroupID;
@dynamic marketGroupName;
@dynamic icon;
@dynamic parentGroup;
@dynamic subGroups;
@dynamic types;

@end

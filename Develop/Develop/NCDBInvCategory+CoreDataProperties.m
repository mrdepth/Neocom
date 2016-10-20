//
//  NCDBInvCategory+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvCategory+CoreDataProperties.h"

@implementation NCDBInvCategory (CoreDataProperties)

+ (NSFetchRequest<NCDBInvCategory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InvCategory"];
}

@dynamic categoryID;
@dynamic categoryName;
@dynamic published;
@dynamic groups;
@dynamic icon;

@end

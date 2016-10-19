//
//  NCAccount+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAccount+CoreDataProperties.h"

@implementation NCAccount (CoreDataProperties)

+ (NSFetchRequest<NCAccount *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Account"];
}

@dynamic characterID;
@dynamic order;
@dynamic uuid;
@dynamic apiKey;
@dynamic mailBox;
@dynamic skillPlans;

@end

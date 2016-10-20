//
//  NCDBCertMasteryLevel+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertMasteryLevel+CoreDataProperties.h"

@implementation NCDBCertMasteryLevel (CoreDataProperties)

+ (NSFetchRequest<NCDBCertMasteryLevel *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CertMasteryLevel"];
}

@dynamic displayName;
@dynamic level;
@dynamic icon;
@dynamic masteries;

@end

//
//  NCDBChrRace+CoreDataProperties.m
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBChrRace+CoreDataProperties.h"

@implementation NCDBChrRace (CoreDataProperties)

+ (NSFetchRequest<NCDBChrRace *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChrRace"];
}

@dynamic raceID;
@dynamic raceName;
@dynamic dgmppCategories;
@dynamic icon;
@dynamic types;

@end

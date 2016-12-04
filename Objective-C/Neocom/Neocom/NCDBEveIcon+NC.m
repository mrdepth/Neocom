//
//  NCDBEveIcon+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon+NC.h"
#import "NCDatabase.h"

@implementation NCDBEveIcon (NC)

+ (instancetype)defaultCategoryIcon {
	return [self defaultGroupIcon];
}

+ (instancetype)defaultGroupIcon {
	return [self iconWithIconFile:@"38_174"];
}

+ (instancetype)defaultTypeIcon {
	return [self iconWithIconFile:@"07_15"];
}

+ (instancetype)iconWithIconFile:(NSString*) file {
	return NCDatabase.sharedDatabase.eveIcons[file];
}

+ (NCFetchedCollection<NCDBEveIcon*>*) eveIconsWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	return [[NCFetchedCollection alloc] initWithEntity:@"EveIcon" predicateFormat:@"iconFile == %@" argumentArray:nil managedObjectContext:managedObjectContext];
}

@end

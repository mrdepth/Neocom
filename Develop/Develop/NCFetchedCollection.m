//
//  NCFetchedCollection.m
//  Develop
//
//  Created by Artem Shimanski on 23.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFetchedCollection.h"
@import CoreData;

@implementation NCFetchedCollection

- (id) initWithEntity:(NSString*) entityName predicateFormat:(NSString*) predicateFormat argumentArray:(NSArray*) argumentArray managedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	if (self = [super init]) {
		self.entityName = entityName;
		self.predicateFormat = predicateFormat;
		self.argumentArray = argumentArray;
		self.managedObjectContext = managedObjectContext;
	}
	return self;
}

- (id) objectAtIndexedSubscript:(NSInteger) index {
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
	request.predicate = [NSPredicate predicateWithFormat:self.predicateFormat argumentArray:[self.argumentArray arrayByAddingObject:@(index)]];
	request.fetchLimit = 1;
	return [[self.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end

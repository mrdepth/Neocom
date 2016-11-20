//
//  NCFetchedCollection.m
//  Neocom
//
//  Created by Artem Shimanski on 23.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFetchedCollection.h"
@import CoreData;

@interface NCFetchedCollection()
@property (strong, nonatomic) NSFetchRequest* fetchRequest;
@end

@implementation NCFetchedCollection

- (id) initWithEntity:(NSString*) entityName predicateFormat:(NSString*) predicateFormat argumentArray:(NSArray*) argumentArray managedObjectContext:(NSManagedObjectContext*) managedObjectContext {
	if (self = [super init]) {
		self.entityName = entityName;
		self.predicateFormat = predicateFormat;
		self.argumentArray = argumentArray ?: @[];
		self.managedObjectContext = managedObjectContext;
		self.fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
		self.fetchRequest.fetchLimit = 1;
	}
	return self;
}

- (id) objectAtIndexedSubscript:(NSInteger) index {
	self.fetchRequest.predicate = [NSPredicate predicateWithFormat:self.predicateFormat argumentArray:[self.argumentArray arrayByAddingObject:@(index)]];
	return [[self.managedObjectContext executeFetchRequest:self.fetchRequest error:nil] lastObject];
}

- (id) objectForKeyedSubscript:(NSString*) key {
	self.fetchRequest.predicate = [NSPredicate predicateWithFormat:self.predicateFormat argumentArray:[self.argumentArray arrayByAddingObject:key ?: [NSNull null]]];
	return [[self.managedObjectContext executeFetchRequest:self.fetchRequest error:nil] lastObject];
}

@end

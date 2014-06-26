//
//  NCImplantSet.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCImplantSet.h"

@implementation NCStorage(NCImplantSet)

- (NSArray*) implantSets {
	__block NSArray *fetchedObjects = nil;
	NSManagedObjectContext* context = [NSThread isMainThread] ? self.managedObjectContext : self.backgroundManagedObjectContext;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"ImplantSet" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
		
		NSError *error = nil;
		fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	}];
	return fetchedObjects;
}

@end

@implementation NCImplantSetData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.implantIDs = [aDecoder decodeObjectForKey:@"implantIDs"];
		self.boosterIDs = [aDecoder decodeObjectForKey:@"boosterIDs"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.implantIDs)
		[aCoder encodeObject:self.implantIDs forKey:@"implantIDs"];
	if (self.boosterIDs)
		[aCoder encodeObject:self.boosterIDs forKey:@"boosterIDs"];
}

@end

@implementation NCImplantSet

@dynamic data;
@dynamic name;


@end

//
//  NCDBEveIcon+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBEveIcon+Neocom.h"
#import "NCDatabase.h"

@implementation NCDBEveIcon (Neocom)

+ (instancetype) defaultIcon {
	static NCDBEveIcon* defaultIcon = nil;
	if (!defaultIcon) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			NCDatabase* database = [NCDatabase sharedDatabase];
			[database.managedObjectContext performBlockAndWait:^{
				NSFetchRequest* request = [database.managedObjectModel fetchRequestTemplateForName:@"DefaultIcon"];
				defaultIcon = [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
				[[defaultIcon image] image];
			}];
		});
	}
	return defaultIcon;
}

+ (instancetype) eveIconWithIconFile:(NSString*) iconFile {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EveIcon"];
	request.predicate = [NSPredicate predicateWithFormat:@"iconFile == %@", iconFile];
	request.fetchLimit = 1;
	__block NSArray* result;
	
	if ([NSThread isMainThread])
		result = [database.managedObjectContext executeFetchRequest:request error:nil];
	else
		[database.backgroundManagedObjectContext performBlockAndWait:^{
			result = [database.backgroundManagedObjectContext executeFetchRequest:request error:nil];
		}];
	return result.count > 0 ? result[0] : nil;
}

@end

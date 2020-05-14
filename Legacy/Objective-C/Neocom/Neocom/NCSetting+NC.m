//
//  NCSetting+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSetting+NC.h"
#import "NCStorage.h"

@implementation NCSetting (NC)

+ (instancetype) settingForKey:(NSString*) key {
	NSFetchRequest* request = [self fetchRequest];
	request.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
	request.fetchLimit = 1;
	NSManagedObjectContext* context = NCStorage.sharedStorage.viewContext;
	NCSetting* setting = [[context executeFetchRequest:request error:nil] lastObject];
	if (!setting) {
		setting = [NSEntityDescription insertNewObjectForEntityForName:@"Setting" inManagedObjectContext:context];
		setting.key = key;
	}
	return setting;
}

@end

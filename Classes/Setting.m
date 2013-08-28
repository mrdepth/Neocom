//
//  Setting.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 27.08.13.
//
//

#import "Setting.h"
#import "EUStorage.h"

@implementation Setting

@dynamic key;
@dynamic value;

+ (Setting*) settingWithKey:(NSString*) key {
	NSManagedObjectContext* context = [[EUStorage sharedStorage] managedObjectContext];
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"Setting" inManagedObjectContext:context];
	NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"Setting"];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"key = %@", key];
	NSArray* results = [context executeFetchRequest:request error:nil];
	if (results.count > 0)
		return results[0];
	else {
		Setting* setting = [[Setting alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
		setting.key = key;
		return setting;
	}
}

@end

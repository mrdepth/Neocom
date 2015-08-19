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

+ (instancetype) certificateUnclaimedIcon {
	static NCDBEveIcon* certificateUnclaimedIcon;
	if (!certificateUnclaimedIcon) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			certificateUnclaimedIcon = [self eveIconWithIconFile:@"79_01"];
		});
	}
	return certificateUnclaimedIcon;
}

+ (instancetype) defaultTypeIcon {
	static NCDBEveIcon* defaultTypeIcon;
	if (!defaultTypeIcon) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			defaultTypeIcon = [self eveIconWithIconFile:@"07_15"];
		});
	}
	return defaultTypeIcon;
}


+ (instancetype) defaultGroupIcon {
	static NCDBEveIcon* defaultGroupIcon;
	if (!defaultGroupIcon) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			defaultGroupIcon = [self eveIconWithIconFile:@"38_174"];
		});
	}
	return defaultGroupIcon;
}


+ (instancetype) eveIconWithIconFile:(NSString*) iconFile {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"EveIcon"];
	request.predicate = [NSPredicate predicateWithFormat:@"iconFile == %@", iconFile];
	request.fetchLimit = 1;
	return [[database.managedObjectContext executeFetchRequest:request error:nil] lastObject];
}

@end

//
//  NCCacheRecord.m
//  Neocom
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecord+CoreDataProperties.h"
#import "NCCacheRecordData+CoreDataClass.h"

@implementation NCCacheRecord

+ (NSFetchRequest<NCCacheRecord *> *)fetchRequestForKey:(NSString*) key account:(NSString*) account {
	NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:@"Record"];
	request.fetchLimit = 1;
	if (key && account)
		request.predicate = [NSPredicate predicateWithFormat:@"key == %@ AND account == %@", key, account];
	else if (key)
		request.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
	else if (account)
		request.predicate = [NSPredicate predicateWithFormat:@"account == %@", account];
	
	return request;
}

- (id) object {
	return self.data.data;
}

- (BOOL) isExpired {
	return !self.date || !self.expireDate || [self.expireDate compare:[NSDate date]] == NSOrderedAscending;
}

@end

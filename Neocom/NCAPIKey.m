//
//  NCAPIKey.m
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCAPIKey.h"
#import "EVEOnlineAPI.h"
#import "NCCache.h"

@implementation NCStorage(NCSetting)

- (NCAPIKey*) apiKeyWithKeyID:(int32_t) keyID {
	NSManagedObjectContext* context = self.managedObjectContext;
	
	__block NSArray *result = nil;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %d", keyID];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		result = [context executeFetchRequest:fetchRequest error:nil];
	}];
	return result.count > 0 ? result[0] : nil;
}

- (NSArray*) allAPIKeys {
	NSManagedObjectContext* context = self.managedObjectContext;
	
	__block NSArray* apiKeys = nil;
	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"APIKey" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		apiKeys = [context executeFetchRequest:fetchRequest error:nil];
	}];
	return apiKeys;
}

@end

@implementation NCAPIKey

@dynamic keyID;
@dynamic vCode;
@dynamic accounts;
@dynamic apiKeyInfo;

@synthesize error = _error;



- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr {
	NSError* error = nil;
	EVEAPIKeyInfo* apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:self.keyID vCode:self.vCode cachePolicy:cachePolicy error:&error progressHandler:nil];
	if (apiKeyInfo) {
		self.apiKeyInfo = apiKeyInfo;
		self.error = nil;
		return YES;
	}
	else {
		self.error = error;
		if (errorPtr)
			*errorPtr = error;
		return NO;
	}
}

@end

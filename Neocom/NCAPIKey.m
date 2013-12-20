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

@interface NCAPIKey()
@property (nonatomic, strong) NCCacheRecord* apiKeyInfoCacheRecord;

@end

@implementation NCAPIKey

@dynamic keyID;
@dynamic vCode;
@synthesize apiKeyInfo = _apiKeyInfo;
@synthesize error = _error;
@synthesize apiKeyInfoCacheRecord = _apiKeyInfoCacheRecord;

+ (instancetype) apiKeyWithKeyID:(NSInteger) keyID {
	return nil;
}


- (EVEAPIKeyInfo*) apiKeyInfo {
	@synchronized(self) {
		if (!_apiKeyInfo && !_error) {
			_apiKeyInfo = self.apiKeyInfoCacheRecord.data;
			
			if (!_apiKeyInfo && ![NSThread isMainThread]) {
				NSError* error = nil;
				self.apiKeyInfo = [EVEAPIKeyInfo apiKeyInfoWithKeyID:self.keyID vCode:self.vCode cachePolicy:NSURLRequestUseProtocolCachePolicy error:&error progressHandler:nil];
				self.error = error;
			}
		}
		return _apiKeyInfo;
	}
}

- (void) setApiKeyInfo:(EVEAPIKeyInfo *)apiKeyInfo {
	_apiKeyInfo = apiKeyInfo;
	self.error = nil;
	NCCache* cache = [NCCache sharedCache];
	if (apiKeyInfo) {
		[cache.managedObjectContext performBlock:^{
			self.apiKeyInfoCacheRecord.data = apiKeyInfo;
			[cache saveContext];
		}];
	}
}

#pragma mark - Private

- (NCCacheRecord*) apiKeyInfoCacheRecord {
	@synchronized(self) {
		if (!_apiKeyInfoCacheRecord) {
			NCCache* cache = [NCCache sharedCache];
			[cache.managedObjectContext performBlockAndWait:^{
				_apiKeyInfoCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"NCAPIKey.apiKeyInfo.%d", self.keyID]];
			}];
		}
		return _apiKeyInfoCacheRecord;
	}
}

@end

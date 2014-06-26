//
//  NCAPIKey.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCStorage.h"

@class NCAPIKey;
@interface NCStorage(NCAPIKey)
- (NCAPIKey*) apiKeyWithKeyID:(int32_t) keyID;
- (NSArray*) allAPIKeys;
@end

@class EVEAPIKeyInfo;
@class EVEAccountStatus;

@interface NCAPIKey : NSManagedObject

@property (nonatomic) int32_t keyID;
@property (nonatomic, strong) NSString * vCode;
@property (nonatomic, strong) NSSet* accounts;
@property (nonatomic, strong) EVEAPIKeyInfo* apiKeyInfo;

@property (nonatomic, strong) NSError* error;

- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr;

@end

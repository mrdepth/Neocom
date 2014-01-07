//
//  NCAccountsManager.h
//  Neocom
//
//  Created by Artem Shimanski on 18.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAccount.h"

@interface NCAccountsManager : NSObject
@property (nonatomic, strong, readonly) NSArray* accounts;
@property (nonatomic, strong, readonly) NSArray* apiKeys;
+ (instancetype) defaultManager;
+ (void) cleanup;

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;
- (void) removeAPIKeyWithKeyID:(NSInteger) keyID;
- (void) removeAccount:(NCAccount*) account;
- (BOOL) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr;
@end

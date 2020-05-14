//
//  NCDataManager.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCache.h"
#import "NCStorage.h"
#import "NCDatabase.h"

@import CoreData;
@import EVEAPI;

@interface NCDataManager : NSObject

+ (instancetype) defaultManager;
- (void) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode completionBlock:(void(^)(NSArray<NSManagedObjectID*>* accounts, NSError* error)) completionBlock;

- (void) characterSheetForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECharacterSheet* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) skillQueueForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVESkillQueue* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;

@end

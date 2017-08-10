//
//  NCDataManager.h
//  Neocom
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCache.h"
#import "NCStorage.h"
#import "NCDatabase.h"
#import "NCLocation.h"

@import CoreData;
@import EVEAPI;

@interface NCDataManager : NSObject

+ (instancetype) defaultManager;
- (void) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode excludeCharacterIDs:(NSIndexSet*) characterIDs completionBlock:(void(^)(NSArray<NSManagedObjectID*>* accounts, NSError* error)) completionBlock;
- (void) apiKeyInfoWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode completionBlock:(void(^)(EVEAPIKeyInfo* apiKeyInfo, NSError* error)) block;

- (void) characterSheetForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECharacterSheet* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) skillQueueForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVESkillQueue* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) characterInfoForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECharacterInfo* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) accountStatusForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVEAccountStatus* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) imageWithCharacterID:(NSInteger) characterID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block;
- (void) imageWithCorporationID:(NSInteger) corporationID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block;
- (void) imageWithAllianceID:(NSInteger) allianceID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block;
- (void) imageWithTypeID:(NSInteger) typeID preferredSize:(CGSize) size scale:(CGFloat) scale cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(UIImage* image, NSError* error, NSManagedObjectID *cacheRecordID)) block;
- (void) callListWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVECallList* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) accountBalanceForAccount:(NCAccount*) account cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(EVEAccountBalance* result, NSError* error, NSManagedObjectID* cacheRecordID)) block;
- (void) locationWithLocationIDs:(NSArray<NSNumber*>*) locationIDs cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(NSDictionary<NSNumber*, NCLocation*>* result, NSError* error)) block;

@end

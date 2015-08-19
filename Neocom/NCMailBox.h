//
//  NCMailBox.h
//  Neocom
//
//  Created by Артем Шиманский on 24.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCTaskManager.h"

typedef NS_ENUM(NSInteger, NCMailBoxContactType){
	NCMailBoxContactTypeCharacter,
	NCMailBoxContactTypeCorporation,
	NCMailBoxContactTypeMailingList
};

@interface NCMailBoxContact : NSObject<NSCoding>
@property (nonatomic, assign) int32_t contactID;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) NCMailBoxContactType type;
@end

@class NCMailBox;
@class EVEMailMessagesItem;
@class EVEMailBodiesItem;
@interface NCMailBoxMessage : NSObject<NSCoding>
@property (nonatomic, weak) NCMailBox* mailBox;
@property (nonatomic, strong) EVEMailMessagesItem* header;
@property (nonatomic, strong) EVEMailBodiesItem* body;
@property (nonatomic, strong) NCMailBoxContact* sender;
@property (nonatomic, strong) NSArray* recipients;
@property (nonatomic, getter = isRead) BOOL read;

- (void) loadBodyWithCompletionBlock:(void(^)(EVEMailBodiesItem* body, NSError* error)) completionBlock;
- (void) clearCache;
@end

@class NCAccount;
@interface NCMailBox : NSManagedObject
@property (nonatomic, strong) NSSet* readedMessagesIDs;
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSDate* updateDate;

@property (nonatomic, strong, readonly) NSArray* messages;
@property (nonatomic, assign, readonly) NSInteger numberOfUnreadMessages;

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy inTask:(NCTask*) task;
- (void) markAsRead:(NSArray*) messages;

@end

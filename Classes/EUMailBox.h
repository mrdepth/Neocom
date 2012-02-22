//
//  EUMailBox.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUMailMessage.h"
#import "EUNotification.h"

@class EVEAccount;
@interface EUMailBox : NSObject {
	NSMutableArray* inbox;
	NSMutableArray* sent;
	NSMutableArray* notifications;
	NSInteger keyID;
	NSString* vCode;
	NSInteger characterID;
	NSError* error;
}
@property (nonatomic, readonly) NSInteger numberOfUnreadMessages;
@property (nonatomic, readonly, retain) NSArray* inbox;
@property (nonatomic, readonly, retain) NSArray* sent;
@property (nonatomic, readonly, retain) NSArray* notifications;
@property (nonatomic, readonly) NSInteger keyID;
@property (nonatomic, readonly, retain) NSString* vCode;
@property (nonatomic, readonly) NSInteger characterID;
@property (nonatomic, readonly, retain) NSError* error;

+ (id) mailBoxWithAccount:(EVEAccount*) account;
- (id) initWithAccount:(EVEAccount*) account;
- (void) save;

@end

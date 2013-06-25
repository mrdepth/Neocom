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
@interface EUMailBox : NSObject
@property (nonatomic, readonly) NSInteger numberOfUnreadMessages;
@property (nonatomic, readonly, strong) NSArray* inbox;
@property (nonatomic, readonly, strong) NSArray* sent;
@property (nonatomic, readonly, strong) NSArray* notifications;
@property (nonatomic, readonly) NSInteger keyID;
@property (nonatomic, readonly, strong) NSString* vCode;
@property (nonatomic, readonly) NSInteger characterID;
@property (nonatomic, readonly, strong) NSError* error;

+ (id) mailBoxWithAccount:(EVEAccount*) account;
- (id) initWithAccount:(EVEAccount*) account;
- (void) save;

@end

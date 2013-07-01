//
//  EVENotification.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUMailBox;
@class EVENotificationTextsItem;
@class EVENotificationsItem;
@interface EUNotification : NSObject
@property (nonatomic, weak) EUMailBox* mailBox;
@property (nonatomic, strong) EVENotificationsItem* header;
@property (nonatomic, strong) EVENotificationTextsItem* details;
@property (nonatomic, strong) NSString* sender;
@property (nonatomic, assign, getter = isRead) BOOL read;

+ (id) notificationWithMailBox:(EUMailBox*) mailBox;
- (id) initWithMailBox:(EUMailBox*) mailBox;

@end

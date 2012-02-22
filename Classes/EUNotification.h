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
@interface EUNotification : NSObject {
	EUMailBox* mailBox;
	EVENotificationsItem* header;
	EVENotificationTextsItem* details;
	NSString* sender;
	BOOL read;
}
@property (nonatomic, assign) EUMailBox* mailBox;
@property (nonatomic, retain) EVENotificationsItem* header;
@property (nonatomic, retain) EVENotificationTextsItem* details;
@property (nonatomic, retain) NSString* sender;
@property (nonatomic, assign, getter = isRead) BOOL read;

+ (id) notificationWithMailBox:(EUMailBox*) mailBox;
- (id) initWithMailBox:(EUMailBox*) mailBox;

@end

//
//  EUNotification.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EUNotification.h"
#import "EUMailBox.h"
#import "EVEOnlineAPI.h"

@implementation EUNotification

+ (id) notificationWithMailBox:(EUMailBox*) mailBox {
	return [[EUNotification alloc] initWithMailBox:mailBox];
}

- (id) initWithMailBox:(EUMailBox*) aMailBox {
	if (self = [super init]) {
		self.mailBox = aMailBox;
	}
	return self;
}

- (EVENotificationTextsItem*) details {
	if (!_details) {
		NSError* error = nil;
		EVENotificationTexts* texts = [EVENotificationTexts notificationTextsWithKeyID:self.mailBox.keyID
																				 vCode:self.mailBox.vCode
																		   characterID:self.mailBox.characterID
																				   ids:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", self.header.notificationID]]
																				 error:&error
																	   progressHandler:nil];
		if (error != nil)
			_details = (EVENotificationTextsItem*) [NSNull null];
		else {
			if (texts.notifications.count > 0) {
				_details = [texts.notifications objectAtIndex:0];
			}
		}
	}
	return _details != (EVENotificationTextsItem*) [NSNull null] ? _details : nil;
}

@end

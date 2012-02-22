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
@synthesize mailBox;
@synthesize header;
@synthesize details;
@synthesize sender;
@synthesize read;

+ (id) notificationWithMailBox:(EUMailBox*) mailBox {
	return [[[EUNotification alloc] initWithMailBox:mailBox] autorelease];
}

- (id) initWithMailBox:(EUMailBox*) aMailBox {
	if (self = [super init]) {
		self.mailBox = aMailBox;
	}
	return self;
}

- (void) dealloc {
	[header release];
	[details release];
	[sender release];
	[super dealloc];
}

- (EVENotificationTextsItem*) details {
	if (!details) {
		NSError* error = nil;
		EVENotificationTexts* texts = [EVENotificationTexts notificationTextsWithKeyID:mailBox.keyID
																				 vCode:mailBox.vCode
																		   characterID:mailBox.characterID
																				   ids:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", header.notificationID]]
																				 error:&error];
		if (error != nil)
			details = (EVENotificationTextsItem*) [NSNull null];
		else {
			if (texts.notifications.count > 0) {
				details = [[texts.notifications objectAtIndex:0] retain];
			}
		}
	}
	return details != (EVENotificationTextsItem*) [NSNull null] ? details : nil;
}

@end

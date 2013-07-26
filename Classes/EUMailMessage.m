//
//  EUMailMessage.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EUMailMessage.h"
#import "EUMailBox.h"
#import "EVEOnlineAPI.h"
#import "NSMutableString+HTML.h"
#import "EVEAccount.h"

@implementation EUMailMessage

+ (id) mailMessageWithMailBox:(EUMailBox*) mailBox {
	return [[EUMailMessage alloc] initWithMailBox:mailBox];
}

- (id) initWithMailBox:(EUMailBox*) aMailBox {
	if (self = [super init]) {
		self.mailBox = aMailBox;
	}
	return self;
}

- (NSString*) text {
	if (!_text) {
		NSError* error = nil;
		EVEMailBodies* bodies = [EVEMailBodies mailBodiesWithKeyID:self.mailBox.account.charAPIKey.keyID
															 vCode:self.mailBox.account.charAPIKey.vCode
													   characterID:self.mailBox.account.character.characterID
															   ids:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", self.header.messageID]]
															 error:&error
												   progressHandler:nil];
		if (error != nil)
			_text = [error localizedDescription];
		else {
			if (bodies.messages.count == 0) {
				_text = (id) [NSNull null];
			}
			else {
				_text = [[bodies.messages objectAtIndex:0] text];
			}
		}
	}
	return (id) _text != [NSNull null] ? _text : nil;
}

@end

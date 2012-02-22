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

@implementation EUMailMessage
@synthesize mailBox;
@synthesize to;
@synthesize from;
@synthesize text;
@synthesize date;
@synthesize header;
@synthesize read;

+ (id) mailMessageWithMailBox:(EUMailBox*) mailBox {
	return [[[EUMailMessage alloc] initWithMailBox:mailBox] autorelease];
}

- (id) initWithMailBox:(EUMailBox*) aMailBox {
	if (self = [super init]) {
		self.mailBox = aMailBox;
	}
	return self;
}

- (void) dealloc {
	[to release];
	[from release];
	[text release];
	[date release];
	[header release];
	[super dealloc];
}

- (NSString*) text {
	if (!text) {
		NSError* error = nil;
		EVEMailBodies* bodies = [EVEMailBodies mailBodiesWithKeyID:mailBox.keyID
															 vCode:mailBox.vCode
													   characterID:mailBox.characterID
															   ids:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", header.messageID]]
															 error:&error];
		if (error != nil)
			text = [[error localizedDescription] retain];
		else {
			if (bodies.messages.count == 0) {
				text = @"Can't load the message body.";
				[text retain];
			}
			else {
/*				NSMutableString *s = [NSMutableString stringWithString:[[bodies.messages objectAtIndex:0] text]];
				[s removeHTMLTags];
				[s replaceHTMLEscapes];
				text = [s retain];*/
				text = [[[bodies.messages objectAtIndex:0] text] retain];
			}
		}
	}
	return text;
}

@end

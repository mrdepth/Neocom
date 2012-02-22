//
//  EUHTTPRequest.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPRequest.h"


@implementation EUHTTPRequest
@synthesize inputStream;
@synthesize message;
@synthesize delegate;

- (id)initWithInputStream:(NSInputStream *)readStream 
				 delegate:(id<EUHTTPRequestDelegate>) anObject {
	if (self = [super init]) {
		self.inputStream = readStream;
		message = CFHTTPMessageCreateEmpty(NULL, YES);
		self.delegate = anObject;
	}
	return self;
}

- (void) dealloc {
	[inputStream close];
	[inputStream release];
	if (message)
		CFRelease(message);
	
	[super dealloc];
}

- (void) run {
	if (self.inputStream) {
		self.inputStream.delegate = self;
		[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.inputStream open];
	}
}

#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventHasBytesAvailable: {
			if (stream == self.inputStream) {
				UInt8 bytes[1024]; 
				NSInteger len = [self.inputStream read:bytes maxLength:1024];
				if (len > 0) {
					CFHTTPMessageAppendBytes(message, bytes, len);
					if (CFHTTPMessageIsHeaderComplete(message)) {
						[self.delegate httpRequest:self didCompleteWithError:nil];
						[self.inputStream close];
						self.inputStream = nil;
					}
				}
			}
			break;
		}
		case NSStreamEventErrorOccurred: {
			[self.delegate httpRequest:self didCompleteWithError:[inputStream streamError]];
			[self.inputStream close];
			self.inputStream = nil;
			break;
		}
		case NSStreamEventEndEncountered: {
			[self.delegate httpRequest:self didCompleteWithError:nil];
			[self.inputStream close];
			self.inputStream = nil;
			break;
		}
		default:
			break;
	}
}

@end

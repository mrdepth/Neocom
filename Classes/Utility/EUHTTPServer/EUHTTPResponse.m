//
//  EUHTTPResponse.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPResponse.h"


@implementation EUHTTPResponse
@synthesize outputStream;
@synthesize outputData;
@synthesize message;
@synthesize delegate;

- (id)initWithOutputStream:(NSOutputStream *)writeStream 
				  delegate:(id<EUHTTPResponseDelegate>) anObject {
	if (self = [super init]) {
		self.outputStream = writeStream;
		self.delegate = anObject;
	}
	return self;
}

- (void) dealloc {
	[outputStream close];
	[outputStream release];
	[outputData release];
	if (message)
		CFRelease(message);
	
	[super dealloc];
}

- (void) run {
	if (self.outputStream) {
		CFDataRef data = CFHTTPMessageCopySerializedMessage(message);
		self.outputData = [NSMutableData dataWithData:(NSData*) data];
		CFRelease(data);
		
		self.outputStream.delegate = self;
		[self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.outputStream open];
	}
}

- (void) setMessage:(CFHTTPMessageRef)value {
	CFRetain(value);
	if (message)
		CFRelease(message);
	message = value;
}

#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	[self retain];
	switch(eventCode) {
		case NSStreamEventHasSpaceAvailable: {
			if (stream == self.outputStream) {
				NSInteger len = [self.outputStream write:[outputData bytes] maxLength:outputData.length];
				[outputData replaceBytesInRange:NSMakeRange(0, len) withBytes:NULL length:0];
				if (outputData.length == 0)
					[self.delegate httpResponse:self didCompleteWithError:nil];
				[self.outputStream close];
				self.outputStream = nil;
			}
			break;
		}
		case NSStreamEventErrorOccurred: {
			[self.delegate httpResponse:self didCompleteWithError:[outputStream streamError]];
			[self.outputStream close];
			self.outputStream = nil;
			break;
		}
		case NSStreamEventEndEncountered: {
			[self.delegate httpResponse:self didCompleteWithError:nil];
			[self.outputStream close];
			self.outputStream = nil;
		}
		default:
			break;
	}
	[self release];
}

@end

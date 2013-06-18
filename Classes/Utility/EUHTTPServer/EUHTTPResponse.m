//
//  EUHTTPResponse.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPResponse.h"


@implementation EUHTTPResponse

- (id)initWithOutputStream:(NSOutputStream *)writeStream 
				  delegate:(id<EUHTTPResponseDelegate>) anObject {
	if (self = [super init]) {
		self.outputStream = writeStream;
		self.delegate = anObject;
	}
	return self;
}

- (void) dealloc {
	[self.outputStream close];
	if (_message)
		CFRelease(_message);
}

- (void) run {
	if (self.outputStream) {
		CFDataRef data = CFHTTPMessageCopySerializedMessage(_message);
		self.outputData = [NSMutableData dataWithData:(__bridge NSData*) data];
		CFRelease(data);
		
		self.outputStream.delegate = self;
		[self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.outputStream open];
	}
}

- (void) setMessage:(CFHTTPMessageRef)value {
	CFRetain(value);
	if (_message)
		CFRelease(_message);
	_message = value;
}

#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventHasSpaceAvailable: {
			if (stream == self.outputStream) {
				NSInteger len = [self.outputStream write:[self.outputData bytes] maxLength:self.outputData.length];
				[self.outputData replaceBytesInRange:NSMakeRange(0, len) withBytes:NULL length:0];
				if (self.outputData.length == 0)
					[self.delegate httpResponse:self didCompleteWithError:nil];
				[self.outputStream close];
				self.outputStream = nil;
			}
			break;
		}
		case NSStreamEventErrorOccurred: {
			[self.delegate httpResponse:self didCompleteWithError:[self.outputStream streamError]];
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
}

@end

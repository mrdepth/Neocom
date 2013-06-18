//
//  EUHTTPRequest.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPRequest.h"
#import "NSString+EUHTTPServer.h"

@implementation EUHTTPRequest

- (id)initWithInputStream:(NSInputStream *)readStream 
				 delegate:(id<EUHTTPRequestDelegate>) anObject {
	if (self = [super init]) {
		self.inputStream = readStream;
		_message = CFHTTPMessageCreateEmpty(NULL, YES);
		self.delegate = anObject;
	}
	return self;
}

- (void) dealloc {
	[self.inputStream close];
	if (self.message)
		CFRelease(self.message);
}

- (void) run {
	if (self.inputStream) {
		self.inputStream.delegate = self;
		[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.inputStream open];
	}
}

- (NSURL*) url {
	return (__bridge_transfer  NSURL*) CFHTTPMessageCopyRequestURL(_message);
}

- (NSString*) method {
	return (__bridge_transfer  NSString*) CFHTTPMessageCopyRequestMethod(_message);
}

- (NSData*) body {
	return  (__bridge_transfer NSData*) CFHTTPMessageCopyBody(_message);
}

- (NSDictionary*) arguments {
	if (!_arguments) {
		_arguments = [[NSMutableDictionary alloc] init];
		
		NSString* query = self.url.query;
		if (query) {
			[_arguments addEntriesFromDictionary:[query httpGetArguments]];
		}
		
		if ([self.contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
			query = [[NSString alloc] initWithData:self.body encoding:NSUTF8StringEncoding];
			[_arguments addEntriesFromDictionary:[query httpGetArguments]];
		}
		else if ([self.contentType isEqualToString:@"multipart/form-data"]) {
			if (self.boundary) {
				NSString* endMark = [NSString stringWithFormat:@"\r\n--%@--", self.boundary];
				NSString* delimiter = [NSString stringWithFormat:@"\r\n--%@", self.boundary];
				NSMutableString* body = [[NSMutableString alloc] initWithData:self.body encoding:NSUTF8StringEncoding];
				NSRange range = [body rangeOfString:endMark];
				if (range.location != NSNotFound) {
					range.length = body.length - range.location;
					[body replaceCharactersInRange:range withString:@""];
				}
				
				NSArray* parts = [body componentsSeparatedByString:delimiter];
				
				for (NSString* part in parts) {
					range = [part rangeOfString:@"\r\n\r\n"];
					if (range.location != NSNotFound) {
						NSString* headersString = [part substringToIndex:range.location];
						NSString* value = [part substringFromIndex:range.location + range.length];
						NSDictionary* headers = [headersString httpHeaders];
						NSString* contentDisposition = [headers valueForKey:@"Content-Disposition"];
						NSDictionary* valueFields = [contentDisposition httpHeaderValueFields];
						NSString* name = [valueFields valueForKey:@"name"];
						NSString* fileName = [valueFields valueForKey:@"filename"];
						if (name && value) {
							if (fileName) {
								NSDictionary* argument = [NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", value, @"value", nil];
								[_arguments setValue:argument forKey:name];
							}
							else
								[_arguments setValue:value forKey:name];
						}
					}
				}
			}
		}
	}
	return _arguments;
}

- (NSString*) contentType {
	if (!_contentType) {
		NSString* contentTypeString = (__bridge_transfer NSString*) CFHTTPMessageCopyHeaderFieldValue(_message, (__bridge CFStringRef) @"Content-Type");
		if ([contentTypeString rangeOfString:@"application/x-www-form-urlencoded"].location != NSNotFound)
			_contentType = @"application/x-www-form-urlencoded";
		else if ([contentTypeString rangeOfString:@"multipart/form-data"].location != NSNotFound)
			_contentType = @"multipart/form-data";
		else
			_contentType = contentTypeString;
	}
	return _contentType;
}

- (NSInteger) contentLength {
	if (_contentLength == 0) {
		NSString* contentLengthString = (__bridge_transfer NSString*) CFHTTPMessageCopyHeaderFieldValue(_message, (__bridge CFStringRef) @"Content-Length");
		_contentLength = [contentLengthString integerValue];
	}
	return _contentLength;
}

- (NSString*) boundary {
	if (!_boundary) {
		if ([self.contentType isEqualToString:@"multipart/form-data"]) {
			NSString* contentTypeString = (__bridge_transfer NSString*) CFHTTPMessageCopyHeaderFieldValue(_message, (__bridge CFStringRef) @"Content-Type");
			NSDictionary* fields = [contentTypeString httpHeaderValueFields];
			_boundary = [fields valueForKey:@"boundary"];
		}
	}
	return _boundary;
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
					CFHTTPMessageAppendBytes(_message, bytes, len);
					if (CFHTTPMessageIsHeaderComplete(_message)) {
						if (self.contentLength > 0) {
							if (self.body.length >= self.contentLength) {
								[self.delegate httpRequest:self didCompleteWithError:nil];
								[self.inputStream close];
								self.inputStream = nil;
							}
						}
						else {
							[self.delegate httpRequest:self didCompleteWithError:nil];
							[self.inputStream close];
							self.inputStream = nil;
						}
					}
				}
			}
			break;
		}
		case NSStreamEventErrorOccurred: {
			[self.delegate httpRequest:self didCompleteWithError:[self.inputStream streamError]];
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

//
//  EUHTTPRequest.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPConnection.h"
#import "EUOperationQueue.h"

@implementation EUHTTPConnection
@synthesize peerName;
@synthesize delegate;
@synthesize request;
@synthesize response;


- (id)initWithInputStream:(NSInputStream *)readStream 
			 outputStream:(NSOutputStream *) writeStream 
					 peer:(NSString *) peerAddress 
				 delegate:(id<EUHTTPConnectionDelegate>) anObject {
	if (self = [super init]) {
		self.delegate = anObject;
		self.request = [[[EUHTTPRequest alloc] initWithInputStream:readStream delegate:self] autorelease];
		self.response = [[[EUHTTPResponse alloc] initWithOutputStream:writeStream delegate:self] autorelease];
	}
	return self;
}

- (void) dealloc {
	[peerName release];
	[request release];
	[response release];
	[super dealloc];
}

- (void) run {
	[self.request run];
}

#pragma mark EUHTTPRequestDelegate<NSObject>

- (void) httpRequest:(EUHTTPRequest*) aRequest didCompleteWithError:(NSError*) error {
	CFURLRef urlRef = CFHTTPMessageCopyRequestURL(aRequest.message);
	
	NSString *query = nil;
	if (urlRef) {
		NSURL *url = (NSURL*) urlRef;
		query = [url query];
		CFRelease(urlRef);
	}

	BOOL canRun = YES;
	
	NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	
	if (query) {
		for (NSString *subquery in [query componentsSeparatedByString:@"&"]) {
			NSArray *components = [subquery componentsSeparatedByString:@"="];
			if (components.count == 2) {
				NSString *value = [[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
				value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[properties setValue:value forKey:[components objectAtIndex:0]];
			}
		}
		if ([[properties valueForKey:@"keyID"] length] == 0)
			[page replaceOccurrencesOfString:@"{error}" withString:@"Error: Enter <b>KeyID</b>" options:0 range:NSMakeRange(0, page.length)];
		else if ([[properties valueForKey:@"vCode"] length] == 0)
			[page replaceOccurrencesOfString:@"{error}" withString:@"Error: Enter <b>Verification Code</b>" options:0 range:NSMakeRange(0, page.length)];
		else {
			canRun = NO;
		}
		
		if (canRun) {
			[page replaceOccurrencesOfString:@"{keyID}" withString:[properties valueForKey:@"keyID"] options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{vCode}" withString:[properties valueForKey:@"vCode"] options:0 range:NSMakeRange(0, page.length)];
		}
	}
	else {
		[page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
		[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
		[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
	}
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
	self.response.message = message;
	CFRelease(message);

	if (canRun) {
		CFHTTPMessageSetBody(self.response.message, (CFDataRef)[page dataUsingEncoding:NSUTF8StringEncoding]);
		[self.response run];
	}
	else {
		NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;
			[self.delegate connection:self
					  didReceiveKeyID:[[properties valueForKey:@"keyID"] integerValue]
								vCode:[properties valueForKey:@"vCode"]
								error:&error];
			if (error) {
				[page replaceOccurrencesOfString:@"{error}" withString:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]] options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{keyID}" withString:[properties valueForKey:@"keyID"] options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{vCode}" withString:[properties valueForKey:@"vCode"] options:0 range:NSMakeRange(0, page.length)];
			}
			else {
				[page replaceOccurrencesOfString:@"{error}" withString:@"Key added" options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			}
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			CFHTTPMessageSetBody(self.response.message, (CFDataRef)[page dataUsingEncoding:NSUTF8StringEncoding]);
			[self.response run];
		}];

		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark EUHTTPResponseDelegate

- (void) httpResponse:(EUHTTPResponse*) response didCompleteWithError:(NSError*) error {
	[self.delegate connectionDidClose:self];
}

@end

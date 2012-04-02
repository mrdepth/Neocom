//
//  EUHTTPRequest.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPConnection.h"

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
	[delegate connection:self didReceiveRequest:aRequest];
}

#pragma mark EUHTTPResponseDelegate

- (void) httpResponse:(EUHTTPResponse*) response didCompleteWithError:(NSError*) error {
	[self.delegate connectionDidClose:self];
}

@end

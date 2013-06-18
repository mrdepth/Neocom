//
//  EUHTTPRequest.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPConnection.h"

@implementation EUHTTPConnection

- (id)initWithInputStream:(NSInputStream *)readStream 
			 outputStream:(NSOutputStream *) writeStream 
					 peer:(NSString *) peerAddress 
				 delegate:(id<EUHTTPConnectionDelegate>) anObject {
	if (self = [super init]) {
		self.delegate = anObject;
		self.request = [[EUHTTPRequest alloc] initWithInputStream:readStream delegate:self];
		self.response = [[EUHTTPResponse alloc] initWithOutputStream:writeStream delegate:self];
	}
	return self;
}

- (void) run {
	[self.request run];
}

#pragma mark EUHTTPRequestDelegate<NSObject>

- (void) httpRequest:(EUHTTPRequest*) aRequest didCompleteWithError:(NSError*) error {
	[self.delegate connection:self didReceiveRequest:aRequest];
}

#pragma mark EUHTTPResponseDelegate

- (void) httpResponse:(EUHTTPResponse*) response didCompleteWithError:(NSError*) error {
	[self.delegate connectionDidClose:self];
}

@end

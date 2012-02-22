//
//  URLImageRequest.m
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "URLImageRequest.h"


@implementation URLImageRequest
@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize data = _data;
@synthesize responseHeaderFields = _responseHeaderFields;

+ (id) requestWithContentsOfURL: (NSURL*) url cacheRecord: (NSDictionary*) cacheRecord delegate: (id<URLImageRequestDelegate>) delegate {
	return [[[URLImageRequest alloc] initWithContentsOfURL:url cacheRecord:cacheRecord delegate:delegate] autorelease];
}

- (id) initWithContentsOfURL: (NSURL*) url cacheRecord: (NSDictionary*) cacheRecord delegate: (id<URLImageRequestDelegate>) delegate {
	if (self = [super init]) {
		self.delegate = delegate;
		self.url = url;
		_data = [[NSMutableData alloc] init];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		
		NSString *lastModified = [cacheRecord valueForKey:@"Last-Modified"];
		NSString *etag = [cacheRecord valueForKey:@"Etag"];
		
		if (lastModified)
			[request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];

		if (etag)
			[request setValue:etag forHTTPHeaderField:@"If-None-Match"];

		[NSURLConnection connectionWithRequest:request delegate:self];
	}
	return self;
}

- (void) dealloc {
	[(NSObject*) _delegate release];
	[_url release];
	[_data release];
	[_responseHeaderFields release];
	[super dealloc];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	_responseHeaderFields = [[response allHeaderFields] retain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_delegate imageRequest:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	UIImage *image = [UIImage imageWithData:_data];
	[_delegate imageRequest:self didReceiveImage:image];
}

@end

//
//  NCURLCache.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 03.09.13.
//
//

#import "NCURLCache.h"
#import "NSData+MD5.h"

@implementation NCURLCache

- (void) storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
	if (request.HTTPBody) {
		NSURLRequest* fakeRequest = [[NSURLRequest alloc] initWithURL:[request.URL URLByAppendingPathComponent:[request.HTTPBody md5]]];
		[super storeCachedResponse:cachedResponse forRequest:fakeRequest];
	}
	else {
		[super storeCachedResponse:cachedResponse forRequest:request];
	}
}

- (NSCachedURLResponse*) cachedResponseForRequest:(NSURLRequest *)request {
	if (request.HTTPBody) {
		NSURLRequest* fakeRequest = [[NSURLRequest alloc] initWithURL:[request.URL URLByAppendingPathComponent:[request.HTTPBody md5]]];
		return [super cachedResponseForRequest:fakeRequest];
	}
	else
		return [super cachedResponseForRequest:request];
}

@end

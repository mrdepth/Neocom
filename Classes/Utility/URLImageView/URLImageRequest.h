//
//  URLImageRequest.h
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class URLImageRequest;

@protocol URLImageRequestDelegate

- (void) imageRequest: (URLImageRequest*) request didReceiveImage: (UIImage*) image;
- (void) imageRequest: (URLImageRequest*) request didFailWithError: (NSError*) error;

@end


@interface URLImageRequest : NSObject {
	id<URLImageRequestDelegate> _delegate;
	NSURL *_url;
	NSMutableData *_data;
	NSDictionary *_responseHeaderFields;
	NSURLConnection *_connection;
}
@property (nonatomic, retain) id<URLImageRequestDelegate> delegate;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, readonly) NSDictionary *responseHeaderFields;

+ (id) requestWithContentsOfURL: (NSURL*) url cacheRecord: (NSDictionary*) cacheRecord delegate: (id<URLImageRequestDelegate>) delegate;
- (id) initWithContentsOfURL: (NSURL*) url cacheRecord: (NSDictionary*) cacheRecord delegate: (id<URLImageRequestDelegate>) delegate;
@end

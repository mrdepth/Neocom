//
//  URLImageViewManager.h
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "URLImageRequest.h"

#define URLImageViewCacheExpireDate @"expireDate"
#define URLImageViewCachePath @"URLImageViewCache"
#define URLImageViewCacheExpireTime (60*60*24)

@class URLImageViewManager;
@protocol URLImageViewManagerDelegate

- (void) imageViewManager: (URLImageViewManager*) manager didReceiveImage: (UIImage*) image;
- (void) imageViewManager: (URLImageViewManager*) manager didFailWithError: (NSError*) error;

@end


@interface URLImageViewManager : NSObject<URLImageRequestDelegate> {
	NSMutableDictionary *_cache;
	NSMutableDictionary *_requests;
	NSMutableDictionary *_delegates;
}

+ (id) sharedManager;
+ (void) cleanup;
+ (NSString*) documentsDirectory;
- (NSString*) cacheDirectory;
- (NSString*) cacheFilePath;
- (NSString*) cachedImagePathWithKey: (NSString*) key;
- (void) requestImageWithContentsOfURL: (NSURL *) url delegate: (id<URLImageViewManagerDelegate>) delegate;
- (void) cancelPreviousRequestWithURL: (NSURL *) url delegate: (id<URLImageViewManagerDelegate>) delegate;
- (void) clear;

@end

//
//  URLImageViewManager.m
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "URLImageViewManager.h"
#import "NSURL+MD5.h"
#import "URLImageRequest.h"

@implementation URLImageViewManager

static URLImageViewManager *singleton = nil;

+ (id) sharedManager {
	@synchronized (self) {
		if (!singleton)
			singleton = [[URLImageViewManager alloc] init];
	}
	return singleton;
}

+ (void) cleanup {
	@synchronized (self) {
		if (singleton) {
			[singleton release];
			singleton = nil;
		}
	}
}

+ (NSString*) documentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];

}

- (NSString*) cacheDirectory {
	return [[URLImageViewManager documentsDirectory] stringByAppendingPathComponent:URLImageViewCachePath];
}

- (NSString*) cacheFilePath {
	return [[self cacheDirectory] stringByAppendingPathComponent:@"cache.plist"];
}

- (NSString*) cachedImagePathWithKey: (NSString*) key {
	return [[self cacheDirectory] stringByAppendingPathComponent:key];
}
	 
- (id) init {
	if (self = [super init]) {
		_cache = [[NSMutableDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:[self cacheFilePath]]] retain];
		if (!_cache)
			_cache = [[NSMutableDictionary dictionary] retain];
		_requests = [[NSMutableDictionary dictionary] retain];
		_delegates = [[NSMutableDictionary dictionary] retain];
		[[NSFileManager defaultManager] createDirectoryAtPath:[self cacheDirectory] withIntermediateDirectories:YES attributes:NO error:nil];
		
		for (NSString *key in [_cache allKeys]) {
			NSDictionary *cacheRecord = [_cache valueForKey:key];
			NSDate *expireDate = [cacheRecord valueForKey:URLImageViewCacheExpireDate];
			if ([[NSDate date] earlierDate:expireDate] == expireDate) {
				[[NSFileManager defaultManager] removeItemAtPath:[self cachedImagePathWithKey:key] error:nil];
				[_cache removeObjectForKey:key];
			}
		}
	} 
	return self;
}

- (void) dealloc {
	[_cache release];
	[_requests release];
	[_delegates release];
	[super dealloc];
}

- (void) requestImageWithContentsOfURL: (NSURL *) url delegate: (id<URLImageViewManagerDelegate>) delegate {
	@synchronized (self) {
		NSString *key = [url md5];
		NSMutableDictionary *cacheRecord = [_cache valueForKey:key];
		if (!cacheRecord) {
			cacheRecord = [NSMutableDictionary dictionary];
			[_cache setValue:cacheRecord forKey:key];
		}
		NSDate *expireDate = [cacheRecord valueForKey:URLImageViewCacheExpireDate];
		UIImage *image = [UIImage imageWithContentsOfFile:[self cachedImagePathWithKey:key]];
		
		if (image && [[NSDate date] laterDate:expireDate] == expireDate)
			[delegate imageViewManager:self didReceiveImage:image];
		else {
			URLImageRequest *request = [_requests valueForKey:key];
			if (!request) {
				request = [URLImageRequest requestWithContentsOfURL:url cacheRecord:(image ? cacheRecord : nil) delegate:self];
				[_requests setValue:request forKey:key];
			}
			
			NSMutableArray *delegatesArray = [_delegates valueForKey:key];
			if (!delegatesArray) {
				delegatesArray = [NSMutableArray array];
				[_delegates setValue:delegatesArray forKey:key];
			}
			[delegatesArray addObject:delegate];
		}
	}
}
							  
- (void) cancelPreviousRequestWithURL: (NSURL *) url delegate: (id<URLImageViewManagerDelegate>) delegate {
	@synchronized (self) {
		NSString *key = [url md5];
		[[_delegates valueForKey:key] removeObject:delegate];
	}
}

- (void) clear {
	[_cache removeAllObjects];
	NSString *path = [self cacheDirectory];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *items = [fileManager contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in items)
		[fileManager removeItemAtPath: [path stringByAppendingPathComponent:item] error:nil];
}

#pragma mark URLImageRequestDelegate

- (void) imageRequest: (URLImageRequest*) request didReceiveImage: (UIImage*) image {
	@synchronized (self) {
		NSString *key = [request.url md5];
		NSString *path = [self cachedImagePathWithKey:key];
		NSMutableDictionary *cacheRecord;
		if (image) {
			cacheRecord = [NSMutableDictionary dictionary];
			[_cache setValue:cacheRecord forKey:key];
		}
		else
			cacheRecord = [_cache valueForKey:key];
		
		NSString *lastModified = [request.responseHeaderFields valueForKey:@"Last-Modified"];
		if (lastModified)
			[cacheRecord setValue:lastModified forKey:@"Last-Modified"];

		NSString *expires = [request.responseHeaderFields valueForKey:@"Expires"];
		if (expires) {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			NSDate *date = [dateFormatter dateFromString:expires];
			[dateFormatter release];
			if ([date laterDate:[NSDate date]] == date)
				[cacheRecord setValue:date forKey:URLImageViewCacheExpireDate];
			else
				[cacheRecord setValue:[NSDate dateWithTimeIntervalSinceNow:URLImageViewCacheExpireTime] forKey:URLImageViewCacheExpireDate];
		}
		else
			[cacheRecord setValue:[NSDate dateWithTimeIntervalSinceNow:URLImageViewCacheExpireTime] forKey:URLImageViewCacheExpireDate];


		NSString *etag = [request.responseHeaderFields valueForKey:@"Etag"];
		if (lastModified)
			[cacheRecord setValue:etag forKey:@"Etag"];


		[_cache writeToURL:[NSURL fileURLWithPath:[self cacheFilePath]] atomically:YES];
		
		if (image)
			[request.data writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
		else
			image = [UIImage imageWithContentsOfFile:path];

		for (id<URLImageViewManagerDelegate> delegate in [_delegates valueForKey:key]) {
			[delegate imageViewManager:self didReceiveImage:image];
		}
		[_requests removeObjectForKey:key];
		[_delegates removeObjectForKey:key];
	}
}

- (void) imageRequest: (URLImageRequest*) request didFailWithError: (NSError*) error {
	@synchronized (self) {
		NSString *key = [request.url md5];
		UIImage *image = [UIImage imageWithContentsOfFile:[self cachedImagePathWithKey:key]];
		
		if (image) {
			for (id<URLImageViewManagerDelegate> delegate in [_delegates valueForKey:key]) {
				[delegate imageViewManager:self didReceiveImage:image];
			}
		}
		else {
			for (id<URLImageViewManagerDelegate> delegate in [_delegates valueForKey:key]) {
				[delegate imageViewManager:self didFailWithError:error];
			}
			[_requests removeObjectForKey:key];
			[_delegates removeObjectForKey:key];
		}
	}
}

@end

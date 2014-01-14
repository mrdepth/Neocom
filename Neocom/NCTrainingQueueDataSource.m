//
//  NCTrainingQueueDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTrainingQueueDataSource.h"
#import "NCAccount.h"

@implementation NCTrainingQueueDataSource

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy error:(NSError**) errorPtr progressHandler:(void(^)(CGFloat progress, BOOL* stop)) progressHandler {
	NCAccount* account = [NCAccount currentAccount];
	[account reloadWithCachePolicy:cachePolicy error:errorPtr progressHandler:progressHandler];
}

@end

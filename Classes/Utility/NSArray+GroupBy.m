//
//  NSArray+GroupBy.m
//  EVEUniverse
//
//  Created by Shimanski on 8/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSArray+GroupBy.h"


@implementation NSArray(GroupBy)

- (NSArray*) arrayGroupedByKey:(NSString*) keyPath {
	NSMutableArray *unknown = [NSMutableArray array];
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	
	for (NSObject *object in self) {
		NSObject<NSCopying> *key = [object valueForKeyPath:keyPath];
		if (!key)
			[unknown addObject:object];
		else {
			NSMutableArray *array = [dic objectForKey:key];
			if (!array) {
				array = [NSMutableArray array];
				[dic setObject:array forKey:key];
			}
			[array addObject:object];
		}
	}
	
	NSMutableArray *result = [NSMutableArray arrayWithArray:[dic allValues]];
	if (unknown.count > 0)
		[result addObject:unknown];
	return result;
}

@end

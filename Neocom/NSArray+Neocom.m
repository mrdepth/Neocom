//
//  NSArray+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 19.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NSArray+Neocom.h"

@implementation NSArray (Neocom)

- (NSArray*) arrayGroupedByKey:(NSString*) keyPath {
	NSMutableArray *unknown = [NSMutableArray new];
	NSMutableDictionary *dic = [NSMutableDictionary new];
	
	for (NSObject *object in self) {
		NSObject<NSCopying>* key = [object valueForKeyPath:keyPath];
		if (!key)
			[unknown addObject:object];
		else {
			NSMutableArray *array = dic[key];
			if (!array) {
				array = [NSMutableArray new];
				dic[key] = array;
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

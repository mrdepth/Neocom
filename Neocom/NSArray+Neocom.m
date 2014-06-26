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

- (NSDictionary*) transitionFromArray:(NSArray *)from {
	NSMutableIndexSet* deleted = [NSMutableIndexSet new];
	NSMutableIndexSet* inserted = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, self.count)];
	NSMutableDictionary* moved = [NSMutableDictionary new];

	NSInteger oldIndex = 0;
	for (id object in from) {
		NSInteger newIndex = [self indexOfObject:object];
		if (newIndex == NSNotFound)
			[deleted addIndex:oldIndex];
		else {
			[inserted removeIndex:newIndex];
			if (newIndex != oldIndex)
				moved[@(oldIndex)] = @(newIndex);
		}
		oldIndex++;
	}
	
	NSMutableDictionary* transition = [NSMutableDictionary new];
	if (deleted.count > 0)
		transition[NSArrayTransitionDeleteKey] = deleted;
	if (inserted.count > 0)
		transition[NSArrayTransitionInsertKey] = inserted;
	if (moved.count > 0)
		transition[NSArrayTransitionMoveKey] = moved;
	
	return transition.count > 0 ? transition : nil;
}

@end

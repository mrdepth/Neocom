//
//  EUFilterItem.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilterItem.h"

@implementation EUFilterItem

+ (id) filterItem {
	return [[EUFilterItem alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
		self.values = [[NSMutableSet alloc] init];
        // Initialization code here.
    }
    
    return self;
}

- (void) updateWithValue:(id) value {
	EUFilterItemValue *itemValue = [[EUFilterItemValue alloc] init];
	itemValue.value = [value valueForKeyPath:self.valuePropertyKey];
	itemValue.title = [value valueForKeyPath:self.titlePropertyKey];
	if (itemValue.value && itemValue.title)
		[self.values addObject:itemValue];
}

- (NSSet*) selectedValues {
	return [self.values filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"enabled=YES"]];
}

- (NSPredicate*) predicate {
	NSMutableArray *selectedValues = [NSMutableArray array];
	for (EUFilterItemValue *value in self.values)
		if (value.enabled)
			[selectedValues addObject:value.value];
	if (selectedValues.count > 0)
		return [NSPredicate predicateWithFormat:@"%K in %@", self.valuePropertyKey, selectedValues];
	else
		return nil;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone {
	EUFilterItem *item = [[EUFilterItem alloc] init];
	item.name = self.name;
	item.allValue = self.allValue;
	item.valuePropertyKey = self.valuePropertyKey;
	item.titlePropertyKey = self.titlePropertyKey;
	item.values = [NSMutableSet setWithSet:self.values];
	return item;
}

@end

//
//  EUFilterItem.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilterItem.h"

@implementation EUFilterItem
@synthesize name;
@synthesize allValue;
@synthesize valuePropertyKey;
@synthesize titlePropertyKey;
@synthesize values;

+ (id) filterItem {
	return [[[EUFilterItem alloc] init] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
		values = [[NSMutableSet alloc] init];
        // Initialization code here.
    }
    
    return self;
}

- (void) dealloc {
	[name release];
	[allValue release];
	[valuePropertyKey release];
	[titlePropertyKey release];
	[values release];
	[super dealloc];
}

- (void) updateWithValue:(id) value {
	EUFilterItemValue *itemValue = [[EUFilterItemValue alloc] init];
	itemValue.value = [value valueForKeyPath:valuePropertyKey];
	itemValue.title = [value valueForKeyPath:titlePropertyKey];
	if (itemValue.value && itemValue.title)
		[values addObject:itemValue];
	[itemValue release];
}

- (NSSet*) selectedValues {
	return [values filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"enabled=YES"]];
}

- (NSPredicate*) predicate {
	NSMutableSet *selectedValues = [NSMutableArray array];
	for (EUFilterItemValue *value in values)
		if (value.enabled)
			[selectedValues addObject:value.value];
	if (selectedValues.count > 0)
		return [NSPredicate predicateWithFormat:@"%K in %@", valuePropertyKey, selectedValues];
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

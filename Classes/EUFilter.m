//
//  EUFilter.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilter.h"

@implementation EUFilter

+ (id) filterWithContentsOfURL:(NSURL*) url {
	return [[EUFilter alloc] initWithContentsOfURL:url];
}

- (id) initWithContentsOfURL:(NSURL*) url {
	if (self = [super init]){
		NSArray *array = [NSArray arrayWithContentsOfURL:url];
		self.filters = [[NSMutableArray alloc] init];
		for (NSDictionary *filter in array) {
			EUFilterItem *item = [[EUFilterItem alloc] init];
			item.name = [filter valueForKey:@"name"];
			item.allValue = [filter valueForKey:@"allValue"];
			item.valuePropertyKey = [filter valueForKey:@"valuePropertyKey"];
			item.titlePropertyKey = [filter valueForKey:@"titlePropertyKey"];
			[self.filters addObject:item];
		}
	}
	return self;
}

- (void) updateWithValues:(NSArray*) values {
	for (id value in values) {
		[self updateWithValue:value];
	}
}

- (void) updateWithValue:(id) value {
	for (EUFilterItem *item in self.filters) {
		[item updateWithValue:value];
	}
}

- (NSArray*) applyToValues:(NSArray*) values {
	NSPredicate *predicate = [self predicate];
	return predicate ? [values filteredArrayUsingPredicate:[self predicate]] : values;
}

- (NSPredicate*) predicate {
	NSMutableArray *predicates = [NSMutableArray array];
	for (EUFilterItem *filterItem in self.filters) {
		NSPredicate *predicate = [filterItem predicate];
		if (predicate)
			[predicates addObject:predicate];
	}
	return predicates.count > 0 ? [NSCompoundPredicate andPredicateWithSubpredicates:predicates] : nil;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone {
	EUFilter *filter = [[EUFilter alloc] init];
	filter.filters = [[NSMutableArray alloc] initWithArray:self.filters copyItems:YES];
	return filter;
}


@end

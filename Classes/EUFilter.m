//
//  EUFilter.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilter.h"

@implementation EUFilter
@synthesize filters;

+ (id) filterWithContentsOfURL:(NSURL*) url {
	return [[[EUFilter alloc] initWithContentsOfURL:url] autorelease];
}

- (id) initWithContentsOfURL:(NSURL*) url {
	if (self = [super init]){
		NSArray *array = [NSArray arrayWithContentsOfURL:url];
		filters = [[NSMutableArray alloc] init];
		for (NSDictionary *filter in array) {
			EUFilterItem *item = [[[EUFilterItem alloc] init] autorelease];
			item.name = [filter valueForKey:@"name"];
			item.allValue = [filter valueForKey:@"allValue"];
			item.valuePropertyKey = [filter valueForKey:@"valuePropertyKey"];
			item.titlePropertyKey = [filter valueForKey:@"titlePropertyKey"];
			[filters addObject:item];
		}
	}
	return self;
}

- (void) dealloc {
	[filters release];
	[super dealloc];
}

- (void) updateWithValues:(NSArray*) values {
	for (id value in values) {
		[self updateWithValue:value];
	}
}

- (void) updateWithValue:(id) value {
	for (EUFilterItem *item in filters) {
		[item updateWithValue:value];
	}
}

- (NSArray*) applyToValues:(NSArray*) values {
	NSPredicate *predicate = [self predicate];
	return predicate ? [values filteredArrayUsingPredicate:[self predicate]] : values;
}

- (NSPredicate*) predicate {
	NSMutableArray *predicates = [NSMutableArray array];
	for (EUFilterItem *filterItem in filters) {
		NSPredicate *predicate = [filterItem predicate];
		if (predicate)
			[predicates addObject:predicate];
	}
	return predicates.count > 0 ? [NSCompoundPredicate andPredicateWithSubpredicates:predicates] : nil;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone {
	EUFilter *filter = [[EUFilter alloc] init];
	filter.filters = [[[NSMutableArray alloc] initWithArray:self.filters copyItems:YES] autorelease];
	return filter;
}


@end

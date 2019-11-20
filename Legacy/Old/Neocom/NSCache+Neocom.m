//
//  NSCache+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 18.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NSCache+Neocom.h"

@implementation NSCache (Neocom)

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey {
	if (object)
		[self setObject:object forKey:aKey];
	else
		[self removeObjectForKey:aKey];
}

- (id) objectForKeyedSubscript:(id)key {
	return [self objectForKey:key];
}


@end

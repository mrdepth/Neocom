//
//  NCCacheRecordData.m
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCacheRecordData.h"
#import "NCCacheRecord.h"

@interface NCCacheRecordData() {
	id _dataValue;
}
@end


@implementation NCCacheRecordData

@dynamic data;
@dynamic record;

- (void) setData:(id)data {
	[self willChangeValueForKey:@"data"];
	_dataValue = data;
	[self setPrimitiveValue:data ? [NSKeyedArchiver archivedDataWithRootObject:data] : nil forKey:@"data"];
	[self didChangeValueForKey:@"data"];
}

- (id) data {
	[self willAccessValueForKey:@"data"];
	if (!_dataValue) {
		id d = [self primitiveValueForKey:@"data"];
		if (d)
			_dataValue = [NSKeyedUnarchiver unarchiveObjectWithData:d];
		else
			_dataValue = [NSNull null];
	}
	[self didAccessValueForKey:@"data"];
	return [_dataValue isKindOfClass:[NSNull class]] ? nil : _dataValue;
}

- (void) didTurnIntoFault {
	[super didTurnIntoFault];
	_dataValue = nil;
}

@end

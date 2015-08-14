//
//  NCLoadout.m
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLoadout.h"
#import "NCLoadoutData.h"
#import "NCStorage.h"
#import "NCDatabase.h"

#define NCCategoryIDShip 6

@implementation NCLoadout
@synthesize type = _type;

@dynamic name;
@dynamic typeID;
@dynamic url;
@dynamic data;
@dynamic tag;

- (NCDBInvType*) type {
	if (!_type) {
		_type = [NCDBInvType invTypeWithTypeID:self.typeID];
	}
	return _type;
}

- (void) setTypeID:(int32_t)typeID {
	[self willChangeValueForKey:@"typeID"];
	[self setPrimitiveValue:@(typeID) forKey:@"typeID"];
	_type = nil;
	[self didChangeValueForKey:@"typeID"];
}

- (NCLoadoutCategory) category {
	return self.type.group.category.categoryID == NCCategoryIDShip ? NCLoadoutCategoryShip : NCLoadoutCategoryPOS;
}

@end

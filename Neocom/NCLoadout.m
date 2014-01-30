//
//  NCLoadout.m
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLoadout.h"
#import "NCLoadoutData.h"
#import "EVEDBAPI.h"

@interface NCLoadout()

@end

@implementation NCLoadout
@synthesize type = _type;

@dynamic loadoutName;
@dynamic imageName;
@dynamic typeID;
@dynamic typeName;
@dynamic url;
@dynamic data;

- (EVEDBInvType*) type {
	if (!_type) {
		_type = [EVEDBInvType invTypeWithTypeID:self.typeID error:nil];
	}
	return _type;
}

- (void) setTypeID:(int32_t)typeID {
	[self willChangeValueForKey:@"typeID"];
	[self setPrimitiveValue:@(typeID) forKey:@"typeID"];
	_type = nil;
	[self didChangeValueForKey:@"typeID"];
}

@end

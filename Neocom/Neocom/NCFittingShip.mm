//
//  NCFittingShip.m
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingShip.h"
#import "NCFittingProtected.h"

@implementation NCFittingShip {
	NSInteger _typeID;
}

- (nonnull instancetype) initWithTypeID:(NSInteger) typeID {
	if (self = [super init]) {
		_typeID = typeID;
	}
	return self;
}

- (NSInteger) typeID {
	return self.item ? [super typeID] : _typeID;
}

@end

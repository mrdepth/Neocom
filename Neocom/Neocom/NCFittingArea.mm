//
//  NCFittingArea.m
//  Neocom
//
//  Created by Artem Shimanski on 13.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import "NCFittingArea.h"
#import "NCFittingProtected.h"

@implementation NCFittingArea {
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

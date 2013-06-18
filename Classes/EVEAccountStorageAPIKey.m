//
//  EVEAccountStorageAPIKey.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorageAPIKey.h"


@implementation EVEAccountStorageAPIKey

- (id) init {
	if (self = [super init]) {
		self.assignedCharacters = [NSMutableArray array];
	}
	return self;
}

- (NSUInteger) hash {
	return self.keyID;
}

- (BOOL) isEqual:(id)object {
	return self.keyID == [object keyID];
}

@end

//
//  EVEAccountStorageAPIKey.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountStorageAPIKey.h"


@implementation EVEAccountStorageAPIKey
@synthesize apiKeyInfo;
@synthesize keyID;
@synthesize vCode;
@synthesize error;
@synthesize assignedCharacters;

- (id) init {
	if (self = [super init]) {
		self.assignedCharacters = [NSMutableArray array];
	}
	return self;
}

- (void) dealloc {
	[vCode release];
	[error release];
	[assignedCharacters release];
	[super dealloc];
}

- (NSUInteger) hash {
	return keyID;
}

- (BOOL) isEqual:(id)object {
	return self.keyID == [object keyID];
}

@end

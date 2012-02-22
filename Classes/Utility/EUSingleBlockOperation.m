//
//  EUSingleBlockOperation.m
//  EVEUniverse
//
//  Created by Shimanski on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUSingleBlockOperation.h"


@implementation EUSingleBlockOperation
@synthesize identifier;

+ (id) operationWithIdentifier:(NSString*) aIdentifier {
	return [[[EUSingleBlockOperation alloc] initWithIdentifier:aIdentifier] autorelease];
}

- (id) initWithIdentifier:(NSString*) aIdentifier {
	if (self = [super init]) {
		self.identifier = aIdentifier;
	}
	return self;
}

- (void) dealloc {
	[identifier release];
	[super dealloc];
}

@end

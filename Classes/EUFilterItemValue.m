//
//  EUFilterItemValue.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilterItemValue.h"

@implementation EUFilterItemValue
@synthesize title;
@synthesize value;
@synthesize enabled;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) dealloc {
	[title release];
	[value release];
	[super dealloc];
}

- (NSUInteger) hash {
	return [value hash];
}

- (BOOL) isEqual:(id)object {
	return [value isEqual:[(EUFilterItemValue*) object value]];
}

@end

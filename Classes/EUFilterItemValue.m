//
//  EUFilterItemValue.m
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUFilterItemValue.h"

@implementation EUFilterItemValue


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (NSUInteger) hash {
	return [self.value hash];
}

- (BOOL) isEqual:(id)object {
	return [self.value isEqual:[(EUFilterItemValue*) object value]];
}

@end

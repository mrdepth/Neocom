//
//  CharacterCellView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CharacterCellView.h"

@implementation CharacterCellView
@synthesize characterNameLabel;

- (void) dealloc {
	[characterNameLabel release];
	[super dealloc];
}

@end

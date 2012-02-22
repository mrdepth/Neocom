//
//  MainMenuCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainMenuCellView.h"


@implementation MainMenuCellView
@synthesize titleLabel;
@synthesize iconImageView;

- (void)dealloc {
	[titleLabel release];
	[iconImageView release];
    [super dealloc];
}


@end

//
//  EUWindow.m
//  EVEUniverse
//
//  Created by Shimanski on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUWindow.h"
#import "Globals.h"

@implementation EUWindow

- (void)didAddSubview:(UIView *)subview {
	UIView *v = [[[Globals appDelegate] loadingViewController] view];
	if (v.superview == self)
		[self bringSubviewToFront:v];
}

@end

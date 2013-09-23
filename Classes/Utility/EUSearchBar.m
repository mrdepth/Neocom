//
//  EUSearchBar.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 23.09.13.
//
//

#import "EUSearchBar.h"

@implementation EUSearchBar

- (void) setFrame:(CGRect)frame {
	if (!self.showsScopeBar)
		frame.size.height = 44;
	[super setFrame:frame];
}

@end

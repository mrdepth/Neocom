//
//  LUIRoundRectButton.m
//  EVEUniverse
//
//  Created by mr_depth on 22.07.13.
//
//

#import "LUIRoundRectButton.h"

@implementation LUIRoundRectButton

- (void) awakeFromNib {
	[super awakeFromNib];
	[self setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
					forState:UIControlStateNormal];
	[self setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
					forState:UIControlStateHighlighted];
}

@end

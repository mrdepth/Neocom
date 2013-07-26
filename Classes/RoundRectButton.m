//
//  RoundRectButton.m
//  EVEUniverse
//
//  Created by mr_depth on 21.07.13.
//
//

#import "RoundRectButton.h"

@implementation RoundRectButton

- (void) awakeFromNib {
	[self setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
							  forState:UIControlStateNormal];
	[self setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
					forState:UIControlStateHighlighted];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

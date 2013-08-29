//
//  UIActionSheet+Neocom.m
//  EVEUniverse
//
//  Created by mr_depth on 03.08.13.
//
//

#import "UIActionSheet+Neocom.h"

@implementation UIActionSheet (Neocom)

- (void)showInWindowFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[self showInView:view.window];
	else
		[self showFromRect:rect inView:view animated:animated];
}


@end

//
//  NCSlideDownAnimationController.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSlideDownAnimationController.h"

@implementation NCSlideDownAnimationController

- (NSTimeInterval) transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.35;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIView* containerView = [transitionContext containerView];
	BOOL isPresenting = toViewController.presentingViewController == fromViewController;
	
	[containerView insertSubview:toViewController.view aboveSubview:fromViewController.view];
	
	CGRect initialFrame = [transitionContext initialFrameForViewController:fromViewController];
	CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
	toViewController.view.frame = isPresenting
	? CGRectMake(finalFrame.origin.x, initialFrame.origin.y - finalFrame.size.height, finalFrame.size.width, finalFrame.size.height)
	: CGRectMake(finalFrame.origin.x, CGRectGetMaxY(initialFrame), finalFrame.size.width, finalFrame.size.height);
	
	
	[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		toViewController.view.frame = finalFrame;
		fromViewController.view.frame = isPresenting
		? CGRectMake(initialFrame.origin.x, CGRectGetMaxY(finalFrame), initialFrame.size.width, initialFrame.size.height)
		: CGRectMake(initialFrame.origin.x, finalFrame.origin.y - initialFrame.size.height, initialFrame.size.width, initialFrame.size.height);
		
	} completion:^(BOOL finished) {
		BOOL wasCancelled = [transitionContext transitionWasCancelled];
		if (wasCancelled) {
			fromViewController.view.frame = initialFrame;
			[toViewController.view removeFromSuperview];
		}
		else {
			[fromViewController.view removeFromSuperview];
		}
		[transitionContext completeTransition:!wasCancelled];
	}];
}

@end

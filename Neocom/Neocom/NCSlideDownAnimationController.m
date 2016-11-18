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
	return [transitionContext isAnimated] ? 0.35 : 0;
}

- (void) animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIView* containerView = [transitionContext containerView];
	UIView* toView = [transitionContext viewForKey:UITransitionContextToViewKey];
	UIView* fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
	
	BOOL isPresenting = toVC.presentingViewController == fromVC;
	
	[containerView insertSubview:toView aboveSubview:fromView];
	
	CGRect initialFrame = [transitionContext initialFrameForViewController:fromVC];
	CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
	toView.frame = isPresenting
	? CGRectMake(finalFrame.origin.x, initialFrame.origin.y - finalFrame.size.height, finalFrame.size.width, finalFrame.size.height)
	: CGRectMake(finalFrame.origin.x, CGRectGetMaxY(initialFrame), finalFrame.size.width, finalFrame.size.height);
	
	
	[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		toView.frame = finalFrame;
		fromView.frame = isPresenting
		? CGRectMake(initialFrame.origin.x, CGRectGetMaxY(finalFrame), initialFrame.size.width, initialFrame.size.height)
		: CGRectMake(initialFrame.origin.x, finalFrame.origin.y - initialFrame.size.height, initialFrame.size.width, initialFrame.size.height);
		
	} completion:^(BOOL finished) {
		BOOL wasCancelled = [transitionContext transitionWasCancelled];
//		if (wasCancelled) {
//			fromViewController.view.frame = initialFrame;
//			[toViewController.view removeFromSuperview];
//		}
//		else {
//			[fromViewController.view removeFromSuperview];
//		}
		[transitionContext completeTransition:!wasCancelled];
	}];
}

@end

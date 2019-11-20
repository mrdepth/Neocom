//
//  NCSlideDownInteractiveTransition.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSlideDownInteractiveTransition.h"

@interface NCSlideDownInteractiveTransition()
@property (nonatomic, strong) UIScrollView* scrollView;
@property (nonatomic, assign) CGFloat startPanOffset;
@property (nonatomic, assign) CGPoint startContentOffset;
@property (nonatomic, assign, getter = isPresenting) BOOL presenting;
@property (nonatomic, strong) UIView* containerView;
@property (nonatomic, assign) CGFloat distance;
@end

@implementation NCSlideDownInteractiveTransition

- (instancetype) initWithScrollView:(UIScrollView*) scrollView {
	if (self = [super init]) {
		self.scrollView = scrollView;
	}
	return self;
}

- (void) startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	[super startInteractiveTransition:transitionContext];
	UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	self.presenting = toViewController.presentingViewController == fromViewController;
	self.startPanOffset = [self.scrollView.panGestureRecognizer translationInView:self.containerView].y;
	self.startContentOffset = self.scrollView.contentOffset;
	self.distance = [transitionContext initialFrameForViewController:fromViewController].size.height;
}

- (void) dealloc {
	self.scrollView = nil;
}

#pragma mark - Private

- (void) setScrollView:(UIScrollView *)scrollView {
	[_scrollView.panGestureRecognizer removeTarget:self action:@selector(onPan:)];
	_scrollView = scrollView;
	[_scrollView.panGestureRecognizer addTarget:self action:@selector(onPan:)];
}

- (void) onPan:(UIPanGestureRecognizer*) recognizer {
	CGPoint t = [recognizer translationInView:self.containerView];
	CGFloat p = (t.y - self.startPanOffset) / self.distance;
	if (recognizer.state == UIGestureRecognizerStateChanged) {
		if (self.presenting) {
			if (p > 0) {
				self.scrollView.contentOffset = self.startContentOffset;
				[self updateInteractiveTransition:p];
			}
			else {
				[self updateInteractiveTransition:0];
			}
		}
		else {
			if (p < 0) {
				[self updateInteractiveTransition:-p];
				self.scrollView.contentOffset = self.startContentOffset;
			}
			else {
				[self updateInteractiveTransition:0];
			}
		}
	}
	else if (recognizer.state == UIGestureRecognizerStateEnded) {
		if ((self.presenting && p > 0) || (!self.presenting && p < 0))
			[self finishInteractiveTransition];
		else
			[self cancelInteractiveTransition];
	}
	else if (recognizer.state == UIGestureRecognizerStateCancelled) {
		[self cancelInteractiveTransition];
	}
}

@end

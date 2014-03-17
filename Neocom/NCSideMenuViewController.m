//
//  NCSideMenuViewController.m
//  Neocom
//
//  Created by Admin on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSideMenuViewController.h"
#import <objc/runtime.h>

@interface NCSideMenuViewControllerEmbedSegue : UIStoryboardSegue

@end

@interface NCSideMenuViewControllerContentSegue : UIStoryboardSegue

@end

@implementation NCSideMenuViewControllerEmbedSegue

- (void) perform {
	NCSideMenuViewController* sourceViewController = [self.sourceViewController sideMenuViewController];
	UIViewController* destinationViewController = self.destinationViewController;
	sourceViewController.menuViewController = destinationViewController;
}

@end

@implementation NCSideMenuViewControllerContentSegue

- (void) perform {
	NCSideMenuViewController* sourceViewController = [self.sourceViewController sideMenuViewController];
	UIViewController* destinationViewController = self.destinationViewController;
	//sourceViewController.contentViewController = destinationViewController;
	//[sourceViewController setContentViewController:destinationViewController animated:sourceViewController.contentViewController != nil];
	[sourceViewController setContentViewController:destinationViewController animated:YES];
}

@end

@interface NCSideMenuViewController ()<UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGAffineTransform startTransform;
- (void) onPan:(UIPanGestureRecognizer*) recognizer;
- (void) onTap:(UITapGestureRecognizer*) recognizer;
- (CGAffineTransform) contentViewTransform;
@end

@interface UIViewController()
@property (nonatomic, weak, readwrite) NCSideMenuViewController* sideMenuViewController;

@end

@implementation UIViewController(NCSideMenuViewController)

- (NCSideMenuViewController*) sideMenuViewController {
	UIViewController* controller = self;
	while (controller && ![controller isKindOfClass:[NCSideMenuViewController class]])
		controller = controller.parentViewController;
	if (!controller) {
		__block __weak UIViewController* (^weakFind)(UIViewController*);
		UIViewController* (^find)(UIViewController*) = ^(UIViewController* parentViewController) {
			for (UIViewController* controller in parentViewController.childViewControllers) {
				if ([controller isKindOfClass:[NCSideMenuViewController class]])
					return controller;
				else {
					UIViewController* child = weakFind(controller);
					if ([child isKindOfClass:[NCSideMenuViewController class]])
						return child;
				}
			}
			return (UIViewController*) nil;
		};
		
		weakFind = find;
		controller = find(self);
	}
	return (NCSideMenuViewController*) controller;
}

- (void) setSideMenuViewController:(NCSideMenuViewController *)sideMenuViewController {
	objc_setAssociatedObject(self, @"sideMenuViewController", sideMenuViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation NCSideMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
	panRecognizer.delegate = self;
	[self.view addGestureRecognizer:panRecognizer];
	
	UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
	
	@try {
		[self performSegueWithIdentifier:@"NCSideMenuViewControllerEmbedSegue" sender:nil];
	}
	@catch (NSException *exception) {
	}
	
	@try {
		[self performSegueWithIdentifier:@"NCSideMenuViewControllerContentSegue" sender:nil];
	}
	@catch (NSException *exception) {
	}

}

- (void) viewDidLayoutSubviews {
	if (self.contentViewController) {
		self.contentViewController.view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.contentViewController.view.bounds] CGPath];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setMenuViewController:(UIViewController *)menuViewController {
	if (self.menuViewController) {
		[self.menuViewController willMoveToParentViewController:nil];
		[self.menuViewController.view removeFromSuperview];
		[self.menuViewController removeFromParentViewController];
	}
	
	_menuViewController = menuViewController;
	[self addChildViewController:menuViewController];
	[self.view addSubview:menuViewController.view];
	CGRect frame = self.view.bounds;
	if (self.contentViewController)
		frame.size.width -= NCSideMenuViewControllermMenuEdgeInset;
	menuViewController.view.frame = frame;
	menuViewController.sideMenuViewController = self;
	
	[menuViewController didMoveToParentViewController:self];
}

- (void) setContentViewController:(UIViewController *)contentViewController {
	[self setContentViewController:contentViewController animated:NO];
}

- (void) setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated {
	if ([contentViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController* navigationController = (UINavigationController*) contentViewController;
		navigationController.topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuIcon.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(onMenu:)];
	}

	[self.menuViewController beginAppearanceTransition:NO animated:animated];
	[contentViewController beginAppearanceTransition:YES animated:animated];

	[self addChildViewController:contentViewController];
	[self.view addSubview:contentViewController.view];
	contentViewController.view.frame = self.view.bounds;
	_menuVisible = NO;
	
	if (_contentViewController) {
		[_contentViewController willMoveToParentViewController:nil];
		contentViewController.view.transform = _contentViewController.view.transform;
		UIViewController* toRemove = _contentViewController;

		[self transitionFromViewController:_contentViewController
						  toViewController:contentViewController
								  duration:animated ? NCSideMenuViewControllerAnimationDuration : 0.0f
								   options:UIViewAnimationOptionCurveEaseOut
								animations:^{
									_contentViewController = contentViewController;
									contentViewController.view.transform = [self contentViewTransform];
								}
								completion:^(BOOL finished) {
									[contentViewController didMoveToParentViewController:self];
									[toRemove removeFromParentViewController];
									[self.menuViewController endAppearanceTransition];
								}];

	}
	else {
		_contentViewController = contentViewController;

		contentViewController.view.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0.0f);
		[UIView animateWithDuration:animated ? NCSideMenuViewControllerAnimationDuration : 0.0f
							  delay:0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^{
							 contentViewController.view.transform = [self contentViewTransform];
						 }
						 completion:^(BOOL finished) {
							 [contentViewController endAppearanceTransition];
							 [contentViewController didMoveToParentViewController:self];
							 [self.menuViewController endAppearanceTransition];
						 }];
	}
	

	
	contentViewController.view.userInteractionEnabled = !self.menuVisible;
	
	
	contentViewController.view.layer.zPosition = 1.0f;
	contentViewController.view.layer.shadowOpacity = 0.5f;
	contentViewController.view.layer.shadowColor = [[UIColor blackColor] CGColor];
	contentViewController.view.layer.shadowRadius = 4.0;
	contentViewController.view.layer.shadowOffset = CGSizeMake(0, 0);
	contentViewController.view.clipsToBounds = NO;
	contentViewController.view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:contentViewController.view.bounds] CGPath];
	contentViewController.sideMenuViewController = self;
	
//	if (self.menuVisible)
//		[self setMenuVisible:NO animated:animated];
}

- (void) setMenuVisible:(BOOL)menuVisible {
	_menuVisible = menuVisible;
	self.contentViewController.view.transform = [self contentViewTransform];
}

- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated {
    BOOL changed = menuVisible != _menuVisible;
    
    void (^willAppear)() = ^{
        if (changed) {
			[self.menuViewController beginAppearanceTransition:menuVisible animated:animated];
			[self.contentViewController beginAppearanceTransition:!menuVisible animated:animated];
        }
    };

    void (^didAppear)() = ^{
        if (changed) {
			[self.menuViewController endAppearanceTransition];
			[self.contentViewController endAppearanceTransition];
        }
    };

    
	if (animated)
		[UIView animateWithDuration:NCSideMenuViewControllerAnimationDuration
							  delay:0
							options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
						 animations:^{
                             willAppear();
							 self.menuVisible = menuVisible;
						 }
						 completion:^(BOOL finished) {
                             didAppear();
						 }];
	else {
		willAppear();
        self.menuVisible = menuVisible;
        didAppear();
	}
	self.contentViewController.view.userInteractionEnabled = !menuVisible;
}

- (void) setFullScreen:(BOOL)fullScreen {
	_fullScreen = fullScreen;
	self.contentViewController.view.transform = [self contentViewTransform];
}

- (void) setFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
	if (animated) {
		[UIView animateWithDuration:NCSideMenuViewControllerAnimationDuration
							  delay:0
							options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
						 animations:^{
							 self.fullScreen = fullScreen;
						 }
						 completion:^(BOOL finished) {
						 }];
	}
	else
		self.fullScreen = fullScreen;
}


- (IBAction)onMenu:(id)sender {
	[self setMenuVisible:YES animated:YES];
}

#pragma mark - Rotation Support

- (BOOL) shouldAutorotate {
	BOOL shouldAutorotate = [super shouldAutorotate];
	if (self.menuViewController)
		shouldAutorotate = shouldAutorotate && [self.menuViewController shouldAutorotate];
	if (self.contentViewController)
		shouldAutorotate = shouldAutorotate && [self.contentViewController shouldAutorotate];
	return shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations {
	NSUInteger supportedInterfaceOrientations = [super supportedInterfaceOrientations];
	if (self.menuViewController)
		supportedInterfaceOrientations &= [self.menuViewController supportedInterfaceOrientations];
	if (self.contentViewController)
		supportedInterfaceOrientations &= [self.contentViewController supportedInterfaceOrientations];
	return supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	if (self.contentViewController)
		return [self.contentViewController preferredInterfaceOrientationForPresentation];
	else if (self.menuViewController)
		return [self.menuViewController preferredInterfaceOrientationForPresentation];
	else
		return [super preferredInterfaceOrientationForPresentation];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (self.contentViewController) {
		CGPoint p = [gestureRecognizer locationInView:self.contentViewController.view];

		if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
			if (self.menuVisible)
				return p.x > -10;
			else
				return p.x < NCSideMenuViewControllermPanWidth;
		}
		else {
			return self.menuVisible && p.x >= 0;
		}
	}
	else
		return NO;
}

#pragma mark - Private

- (void) onPan:(UIPanGestureRecognizer*) recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		self.startTransform = self.contentViewController.view.transform;
	}
	if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
		CGFloat dx = [recognizer translationInView:self.view].x;
		CGAffineTransform transform = CGAffineTransformConcat(self.startTransform, CGAffineTransformMakeTranslation(dx, 0.0f));
		if (transform.tx < 0.0f)
			transform.tx = 0.0f;
		self.contentViewController.view.transform = transform;

	}
	else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
		if ([recognizer velocityInView:self.view].x > 0)
			[self setMenuVisible:YES animated:YES];
		else
			[self setMenuVisible:NO animated:YES];
	}
}

- (void) onTap:(UITapGestureRecognizer *)recognizer {
	CGPoint p = [recognizer locationInView:self.contentViewController.view];
	if (self.menuVisible && p.x >= 0)
		[self setMenuVisible:NO animated:YES];
	
}

- (CGAffineTransform) contentViewTransform {
	if (self.menuVisible) {
		if (self.fullScreen)
			return CGAffineTransformMakeTranslation(self.view.frame.size.width, 0.0f);
		else
			return CGAffineTransformMakeTranslation(self.view.frame.size.width - NCSideMenuViewControllermMenuEdgeInset, 0.0f);
	}
	else
		return CGAffineTransformIdentity;
}

@end

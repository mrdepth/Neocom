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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIViewController* sourceViewController = self.sourceViewController;
		UIViewController* oldController = sourceViewController.splitViewController.viewControllers[1];
		if ([oldController isKindOfClass:[UINavigationController class]]) {
			UINavigationController* navigationController = (UINavigationController*) oldController;
			if (navigationController.viewControllers.count > 0)
				oldController = navigationController.viewControllers[0];
			else
				oldController = nil;
		}
		if (oldController) {
			UIViewController* controller = nil;
			if ([self.destinationViewController isKindOfClass:[UINavigationController class]]) {
				controller = [self.destinationViewController viewControllers][0];
			}
			else
				controller = self.destinationViewController;
			controller.navigationItem.leftBarButtonItem = oldController.navigationItem.leftBarButtonItem;
		}
		
		NSArray* viewControllers = @[sourceViewController.splitViewController.viewControllers[0], self.destinationViewController];
		sourceViewController.splitViewController.viewControllers = viewControllers;
	}
	else {
		NCSideMenuViewController* sourceViewController = [self.sourceViewController sideMenuViewController];
		UIViewController* destinationViewController = self.destinationViewController;
		[sourceViewController setContentViewController:destinationViewController animated:YES];
	}
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

	_menuVisible = YES;
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
	if (_menuViewController) {
		[_menuViewController willMoveToParentViewController:nil];
		[_menuViewController.view removeFromSuperview];
		[_menuViewController removeFromParentViewController];
	}
	_menuViewController = menuViewController;
	[self addChildViewController:menuViewController];

	if (self.menuVisible)
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

	contentViewController.view.userInteractionEnabled = !self.menuVisible;
	contentViewController.view.layer.zPosition = 1.0f;
	contentViewController.view.layer.shadowOpacity = 0.5f;
	contentViewController.view.layer.shadowColor = [[UIColor blackColor] CGColor];
	contentViewController.view.layer.shadowRadius = 4.0;
	contentViewController.view.layer.shadowOffset = CGSizeMake(0, 0);
	contentViewController.view.clipsToBounds = NO;
	contentViewController.view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:contentViewController.view.bounds] CGPath];
	contentViewController.sideMenuViewController = self;
	contentViewController.view.frame = self.view.bounds;
	
	if (_contentViewController) {
		[_contentViewController willMoveToParentViewController:nil];
		[_contentViewController.view removeFromSuperview];
		[_contentViewController removeFromParentViewController];
		contentViewController.view.transform = _contentViewController.view.transform;
	}
	else
		contentViewController.view.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0.0f);
	
	_contentViewController = contentViewController;
	[self setMenuVisible:NO animated:animated];
}

- (void) setMenuVisible:(BOOL)menuVisible {
	_menuVisible = menuVisible;
	self.contentViewController.view.transform = [self contentViewTransform];
}

- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated {
	BOOL noParent = self.contentViewController.parentViewController == nil;
	
    void (^willAppear)() = ^{
		[self.menuViewController beginAppearanceTransition:menuVisible animated:animated];
		[self.contentViewController beginAppearanceTransition:!menuVisible animated:animated];
		[UIView setAnimationsEnabled:NO];
		if (menuVisible && !self.menuViewController.view.superview) {
			[self.view addSubview:self.menuViewController.view];
			self.menuViewController.view.frame = self.view.bounds;
		}
		if (noParent) {
			[self addChildViewController:self.contentViewController];
			[self.view addSubview:self.contentViewController.view];
			[self.view setNeedsLayout];
			[self.view layoutIfNeeded];
		}
		[UIView setAnimationsEnabled:YES];
    };

    void (^didAppear)() = ^{
		[self.menuViewController endAppearanceTransition];
		[self.contentViewController endAppearanceTransition];

		if (!menuVisible)
			[self.menuViewController.view removeFromSuperview];
		if (noParent)
			[self.contentViewController didMoveToParentViewController:self];
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
		self.contentViewController.view.userInteractionEnabled = NO;
		self.menuViewController.view.userInteractionEnabled = NO;
		
		if (self.menuVisible) {
			[self.menuViewController beginAppearanceTransition:NO animated:NO];
		}
		else {
			[self.contentViewController beginAppearanceTransition:NO animated:NO];
		}
		
		if (!self.menuViewController.view.superview) {
			[self.view addSubview:self.menuViewController.view];
			self.menuViewController.view.frame = self.view.bounds;
		}
		
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
		self.contentViewController.view.userInteractionEnabled = YES;
		self.menuViewController.view.userInteractionEnabled = YES;

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

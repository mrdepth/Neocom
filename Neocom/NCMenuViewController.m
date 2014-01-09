//
//  NCMenuViewController.m
//  Neocom
//
//  Created by Admin on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMenuViewController.h"


@interface NCMenuViewControllerEmbedSegue : UIStoryboardSegue

@end

@interface NCMenuViewControllerContentSegue : UIStoryboardSegue

@end

@implementation NCMenuViewControllerEmbedSegue

- (void) perform {
	NCMenuViewController* sourceViewController = self.sourceViewController;
	UIViewController* destinationViewController = self.destinationViewController;
	sourceViewController.menuViewController = destinationViewController;
}

@end

@implementation NCMenuViewControllerContentSegue

- (void) perform {
	NCMenuViewController* sourceViewController = self.sourceViewController;
	UIViewController* destinationViewController = self.destinationViewController;
	sourceViewController.contentViewController = destinationViewController;
}

@end

@interface NCMenuViewController ()<UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGAffineTransform startTransform;
- (void) onPan:(UIPanGestureRecognizer*) recognizer;
- (void) onTap:(UITapGestureRecognizer*) recognizer;
@end

@implementation NCMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
	panRecognizer.delegate = self;
	[self.view addGestureRecognizer:panRecognizer];
	
	UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
	
	[self performSegueWithIdentifier:@"NCMenuViewControllerEmbedSegue" sender:nil];
	[self performSegueWithIdentifier:@"NCMenuViewControllerContentSegue" sender:nil];
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
		frame.size.width -= NCMenuViewControllermMenuEdgeInset;
	menuViewController.view.frame = frame;
	
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

	[self addChildViewController:contentViewController];
	[self.view addSubview:contentViewController.view];
	
	CGRect frame = self.view.bounds;
	contentViewController.view.frame = frame;
	
	if (_contentViewController) {
		[_contentViewController willMoveToParentViewController:nil];
		[_contentViewController.view removeFromSuperview];
		[_contentViewController removeFromParentViewController];
	}
	
	contentViewController.view.transform = self.menuVisible ? CGAffineTransformMakeTranslation(self.view.frame.size.width - NCMenuViewControllermMenuEdgeInset, 0) : CGAffineTransformIdentity;

	_contentViewController = contentViewController;
	[contentViewController didMoveToParentViewController:self];
	
	contentViewController.view.userInteractionEnabled = !self.menuVisible;
	
	
	contentViewController.view.layer.zPosition = 1.0f;
	contentViewController.view.layer.shadowOpacity = 0.5f;
	contentViewController.view.layer.shadowColor = [[UIColor blackColor] CGColor];
	contentViewController.view.layer.shadowRadius = 4.0;
	contentViewController.view.layer.shadowOffset = CGSizeMake(0, 0);
	contentViewController.view.clipsToBounds = NO;
	contentViewController.view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:contentViewController.view.bounds] CGPath];
}

- (void) setMenuVisible:(BOOL)menuVisible {
	_menuVisible = menuVisible;
	self.contentViewController.view.transform = menuVisible ? CGAffineTransformMakeTranslation(self.view.frame.size.width - NCMenuViewControllermMenuEdgeInset, 0) : CGAffineTransformIdentity;
}

- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated {
    BOOL changed = menuVisible != _menuVisible;
    
    void (^willAppear)() = ^{
        if (changed) {
            if (menuVisible) {
                [self.menuViewController viewWillAppear:animated];
                [self.contentViewController viewWillDisappear:animated];
            }
            else {
                [self.menuViewController viewWillDisappear:animated];
                [self.contentViewController viewWillAppear:animated];
            }
        }
    };

    void (^didAppear)() = ^{
        if (changed) {
            if (menuVisible) {
                [self.menuViewController viewDidAppear:animated];
                [self.contentViewController viewDidDisappear:animated];
            }
            else {
                [self.menuViewController viewDidDisappear:animated];
                [self.contentViewController viewDidAppear:animated];
            }
        }
    };

    
	if (animated)
		[UIView animateWithDuration:NCMenuViewControllerAnimationDuration
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
				return p.x < NCMenuViewControllermPanWidth;
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
		self.contentViewController.view.transform = CGAffineTransformConcat(self.startTransform, CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, 0));

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

@end

//
//  NCMenuViewController.m
//  Neocom
//
//  Created by Admin on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMenuViewController.h"

#define NCMenuViewControllerAnimationDuration 0.35
#define NCMenuViewControllermMenuEdgeInset 40.0
#define NCMenuViewControllermPanWidth 20.0

@interface NCMenuViewControllerEmbedSegue : UIStoryboardSegue

@end

@interface NCMenuViewControllerContentSegue : UIStoryboardSegue

@end

@interface NCMenuViewControllerShadowView : UIView

@end

@implementation NCMenuViewControllerEmbedSegue

- (void) perform {
	NCMenuViewController* sourceViewController = self.sourceViewController;
	UIViewController* destinationViewController = self.destinationViewController;
	sourceViewController.menuViewController = destinationViewController;
	
	/**/
	
}

@end

@implementation NCMenuViewControllerContentSegue

- (void) perform {
	NCMenuViewController* sourceViewController = self.sourceViewController;
	UIViewController* destinationViewController = self.destinationViewController;
	sourceViewController.contentViewController = destinationViewController;

/*	*/
	
	
}

@end

@implementation NCMenuViewControllerShadowView

- (id) initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		//self.backgroundColor = [UIColor whiteColor];
		
		self.layer.shadowOpacity = 1.0f;
		self.layer.shadowColor = [[UIColor blackColor] CGColor];
		self.layer.shadowRadius = 3.0;
		self.layer.shadowOffset = CGSizeMake(0, 0);
		self.clipsToBounds = NO;
		self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
		self.layer.shouldRasterize = YES;
	}
	return self;
}

- (void) layoutSubviews {
	[super layoutSubviews];
	self.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.bounds] CGPath];
}

@end

@interface NCMenuViewController ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) NCMenuViewControllerShadowView* shadowView;
@property (nonatomic, assign) CGAffineTransform startTransform;
- (void) onPan:(UIPanGestureRecognizer*) recognizer;
- (void) onTap:(UITapGestureRecognizer*) recognizer;
@end

@implementation NCMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.shadowView = [[NCMenuViewControllerShadowView alloc] initWithFrame:self.view.bounds];
	self.shadowView.layer.zPosition = 1.0f;
	[self.view addSubview:self.shadowView];
	
	UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
	panRecognizer.delegate = self;
	[self.view addGestureRecognizer:panRecognizer];
	
	UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
	
	[self performSegueWithIdentifier:@"NCMenuViewControllerEmbedSegue" sender:nil];
	[self performSegueWithIdentifier:@"NCMenuViewControllerContentSegue" sender:nil];
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
	contentViewController.view.layer.zPosition = 2.0f;
	[self addChildViewController:contentViewController];
	[self.view addSubview:contentViewController.view];
	
	CGRect frame = self.view.bounds;
	contentViewController.view.frame = frame;
	
	if (_contentViewController) {
		contentViewController.view.transform = self.menuVisible ? CGAffineTransformMakeTranslation(self.view.frame.size.width - NCMenuViewControllermMenuEdgeInset, 0) : CGAffineTransformIdentity;
		[_contentViewController willMoveToParentViewController:nil];
		[_contentViewController.view removeFromSuperview];
		[_contentViewController removeFromParentViewController];
	}
	else {
		contentViewController.view.transform = self.menuVisible ? CGAffineTransformMakeTranslation(self.view.frame.size.width - NCMenuViewControllermMenuEdgeInset, 0) : CGAffineTransformIdentity;
	}
	self.shadowView.transform = contentViewController.view.transform;

	_contentViewController = contentViewController;
	[contentViewController didMoveToParentViewController:self];
	
	contentViewController.view.userInteractionEnabled = !self.menuVisible;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSLog(@"%@", segue);
}

- (void) setMenuVisible:(BOOL)menuVisible {
	_menuVisible = menuVisible;
	self.contentViewController.view.transform = menuVisible ? CGAffineTransformMakeTranslation(self.view.frame.size.width - NCMenuViewControllermMenuEdgeInset, 0) : CGAffineTransformIdentity;
	self.shadowView.transform = self.contentViewController.view.transform;
}

- (void) setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated {
	if (animated)
		[UIView animateWithDuration:NCMenuViewControllerAnimationDuration
							  delay:0
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 [self.menuViewController viewWillAppear:animated];
							 self.menuVisible = menuVisible;
						 }
						 completion:^(BOOL finished) {
							 [self.menuViewController viewDidAppear:animated];
						 }];
	else {
		[self.menuViewController viewWillAppear:animated];
		self.menuVisible = YES;
		[self.menuViewController viewDidAppear:animated];
	}
	self.contentViewController.view.userInteractionEnabled = !menuVisible;
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
			return p.x >= 0;
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
		self.shadowView.transform = self.contentViewController.view.transform;

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

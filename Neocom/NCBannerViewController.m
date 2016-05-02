//
//  NCBannerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCBannerViewController.h"
#import "ASInAppPurchase.h"
//#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Appodeal/Appodeal.h>
#import "NCSkillPlanViewController.h"

@interface NCBannerView()
@property (nonatomic, assign) CGSize intrinsicContentSize;
@end

@implementation NCBannerView

- (CGSize) intrinsicContentSize {
	return _intrinsicContentSize;
}

- (CGFloat) length {
	return self.frame.size.height;
}

@end


@interface NCBannerViewController ()<AppodealBannerViewDelegate>
//@property (nonatomic, strong) IBOutlet GADBannerView* gadBannerView;
@property (nonatomic, strong) AppodealBannerView* adBannerView;
@property (nonatomic, weak) UIView* transitionView;
- (void) updateBanner;
- (void) updateFrame;
@end

@implementation NCBannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidRemoveAdds:) name:NCApplicationDidRemoveAddsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

	[self performSelector:@selector(updateBanner) withObject:nil afterDelay:10];
	
	
	UIView* transitionView;
	for (transitionView in self.view.subviews)
		if ([transitionView isKindOfClass:NSClassFromString(@"UINavigationTransitionView")])
			break;
	
	if (!transitionView && self.view.subviews.count > 0)
		transitionView = self.view.subviews[0];
	self.transitionView = transitionView;
//	self.view.backgroundColor = [UIColor blackColor];
	
	self.bannerView = [[NCBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0)];
	self.bannerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.bannerView];
}

- (void) dealloc {
	[self.bannerView removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCSkillPlanViewController"]) {
		NCSkillPlanViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.xmlData = sender[@"data"];
		controller.skillPlanName = sender[@"name"];
	}
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//	self.transitionView.frame = self.view.bounds;
//	self.bannerView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0);
	//[self.adBannerView removeFromSuperview];
	[self updateFrame];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	/*CGSize size = CGSizeFromGADAdSize(self.gadBannerView.adSize);
	CGSize bannerSize = CGSizeMake(self.view.frame.size.width, 50);
	if (!CGSizeEqualToSize(bannerSize, size)) {
		self.gadBannerView.adSize = GADAdSizeFromCGSize(bannerSize);
	}*/
	
	[self updateFrame];
}

- (void) setToolbarHidden:(BOOL)toolbarHidden animated:(BOOL)animated {
	[super setToolbarHidden:toolbarHidden animated:animated];
	CAAnimation* animation = [[self.toolbar.layer animationForKey:@"position"] mutableCopy];
	[self updateFrame];

	if (animation) {
		[self.toolbar.layer removeAnimationForKey:@"position"];
		CGPoint from = [[animation valueForKey:@"fromValue"] CGPointValue];
		from.y = self.toolbar.layer.position.y;
		[animation setValue:[NSValue valueWithCGPoint:from] forKey:@"fromValue"];
		[self.toolbar.layer addAnimation:animation forKey:@"position"];
	}
}

#pragma mark - AppodealBannerViewDelegate

- (void)bannerViewDidLoadAd:(AppodealBannerView *)bannerView {
	if (!self.adBannerView.superview) {
		[self.bannerView addSubview:self.adBannerView];
		[self.bannerView setNeedsLayout];
		[self updateFrame];
	}
}

- (void)bannerView:(AppodealBannerView *)bannerView didFailToLoadAdWithError:(NSError *)error {
	if (self.adBannerView.superview) {
		[self.adBannerView removeFromSuperview];
		[self updateFrame];
	}
}

/*#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
	if (!self.gadBannerView.superview) {
		[self.bannerView addSubview:self.gadBannerView];
		[self.bannerView setNeedsLayout];
		[self updateFrame];
	}
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	if (self.gadBannerView.superview) {
		[self.gadBannerView removeFromSuperview];
		[self updateFrame];
	}
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
	
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
	
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
	
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
	
}*/

#pragma mark - Unwind

- (IBAction) unwindFromSkillPlanImport:(UIStoryboardSegue*) segue {
	
}

- (IBAction) unwindToAccounts:(UIStoryboardSegue*)sender {
	
}

#pragma mark - Private

- (void) applicationDidRemoveAdds:(NSNotification*) notification {
	if (self.adBannerView.superview) {
		[self.adBannerView removeFromSuperview];
		self.bannerView.intrinsicContentSize = CGSizeZero;
		[self.bannerView invalidateIntrinsicContentSize];
		[self updateFrame];
		[Appodeal hideBanner];
	}
	self.adBannerView = nil;
}

- (void) applicationDidBecomeActive:(NSNotification*) notification {
	[self updateBanner];
}

- (void) applicationWillResignActive:(NSNotification*) notification {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) updateBanner {
	static int retry= 0;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	ASInAppPurchase* purchase = [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID];
	if (purchase || retry >= 3) {
		retry = 0;
		if (purchase.purchased) {
			if (self.adBannerView.superview) {
				[self.adBannerView removeFromSuperview];
				self.bannerView.intrinsicContentSize = CGSizeZero;
				[self.bannerView invalidateIntrinsicContentSize];
				self.adBannerView = nil;
				[self updateFrame];
				[Appodeal hideBanner];
			}
		}
		else {
			if (!self.adBannerView) {
				//self.adBannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(CGSizeMake(self.view.frame.size.width, 50)) origin:CGPointMake(0, 0)];
				self.adBannerView = [[AppodealBannerView alloc] initWithSize:kAppodealUnitSize_320x50 rootViewController:self];
				//self.gadBannerView.rootViewController = self;
				//self.gadBannerView.adUnitID = @"ca-app-pub-0434787749004673/2607342948";
				self.adBannerView.delegate = self;
				
				//GADRequest *request = [GADRequest request];
				//[self.gadBannerView loadRequest:request];
				[self.adBannerView loadAd];
			}
		}
	}
	else {
		retry++;
		[self performSelector:@selector(updateBanner) withObject:nil afterDelay:2];
	}
	
}

- (void) updateFrame {
	CGSize size = CGSizeZero;
	if (self.adBannerView.superview)
		size = kAppodealUnitSize_320x50;
		//size = CGSizeFromGADAdSize(self.gadBannerView.adSize);
	
	CGRect frame = self.bannerView.frame;
	CGFloat y = CGRectGetMaxY(self.view.bounds);
	frame.size.height = size.height;
	frame.origin.y = y - frame.size.height;
	self.bannerView.frame = frame;
	self.adBannerView.frame = self.bannerView.bounds;
	
	frame = self.transitionView.frame;
	frame.size.height = self.bannerView.frame.origin.y - frame.origin.y;
	if (!CGRectEqualToRect(self.transitionView.frame, frame))
		self.transitionView.frame = frame;
	
	frame = self.toolbar.frame;
	frame.origin.y = self.bannerView.frame.origin.y - frame.size.height;
	self.toolbar.frame = frame;
}

@end

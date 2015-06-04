//
//  NCBannerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCBannerViewController.h"
#import "ASInAppPurchase.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "NCSkillPlanViewController.h"

@interface NCBannerView()
@property (nonatomic, assign) CGSize intrinsicContentSize;
@end

@implementation NCBannerView

- (CGSize) intrinsicContentSize {
	return _intrinsicContentSize;
}

@end


@interface NCBannerViewController ()<GADBannerViewDelegate>
@property (nonatomic, strong) IBOutlet GADBannerView* gadBannerView;
@property (nonatomic, weak) UIView* transitionView;
- (void) updateBanner;
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
	self.bannerView.intrinsicContentSize = CGSizeZero;
	
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
	
	self.bannerView = [[NCBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0)];
	self.bannerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.bannerView];
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

- (void) traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
	[super traitCollectionDidChange: previousTraitCollection];
	if (self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass || self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
	}
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	CGSize size = CGSizeFromGADAdSize(self.gadBannerView.adSize);
	CGSize bannerSize = CGSizeMake(self.view.frame.size.width, 50);
	if (!CGSizeEqualToSize(bannerSize, size))
		self.gadBannerView.adSize = GADAdSizeFromCGSize(bannerSize);
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
	CGSize size = CGSizeFromGADAdSize(self.gadBannerView.adSize);
	self.bannerView.frame = CGRectMake(0, self.view.frame.size.height - size.height, self.view.frame.size.width, size.height);
	self.transitionView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.bannerView.frame.origin.y);
	if (!self.gadBannerView.superview) {
		[self.bannerView addSubview:self.gadBannerView];
	}
//	[self.view setNeedsLayout];
//	[self.view layoutIfNeeded];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	if (self.gadBannerView.superview) {
		self.transitionView.frame = self.view.bounds;
		self.bannerView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 0);
		[self.gadBannerView removeFromSuperview];
		//self.bannerView.intrinsicContentSize = CGSizeZero;
		//[self.bannerView invalidateIntrinsicContentSize];
	}
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
	
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
	
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
	
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
	
}

#pragma mark - Unwind

- (IBAction) unwindFromSkillPlanImport:(UIStoryboardSegue*) segue {
	
}

- (IBAction) unwindToAccounts:(UIStoryboardSegue*)sender {
	
}

#pragma mark - Private

- (void) applicationDidRemoveAdds:(NSNotification*) notification {
	if (self.gadBannerView.superview) {
		[self.gadBannerView removeFromSuperview];
		self.bannerView.intrinsicContentSize = CGSizeZero;
		[self.bannerView invalidateIntrinsicContentSize];
	}
	self.gadBannerView = nil;
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
			if (self.gadBannerView.superview) {
				[self.gadBannerView removeFromSuperview];
				self.bannerView.intrinsicContentSize = CGSizeZero;
				[self.bannerView invalidateIntrinsicContentSize];
				self.gadBannerView = nil;
			}
		}
		else {
			if (!self.gadBannerView) {
				self.gadBannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(CGSizeMake(self.view.frame.size.width, 50)) origin:CGPointMake(0, 0)];
//				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
					//self.gadBannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(CGSizeMake(320, 50)) origin:CGPointMake(0, 0)];
//				else
//					self.gadBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait origin:CGPointMake(0, 0)];
				
				self.gadBannerView.rootViewController = self;
				self.gadBannerView.adUnitID = @"ca-app-pub-0434787749004673/2607342948";
				self.gadBannerView.delegate = self;
				
				GADRequest *request = [GADRequest request];
				[self.gadBannerView loadRequest:request];
			}
		}
	}
	else {
		retry++;
		[self performSelector:@selector(updateBanner) withObject:nil afterDelay:10];
	}
	
}

@end

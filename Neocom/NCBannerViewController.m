//
//  NCBannerViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCBannerViewController.h"
#import "ASInAppPurchase.h"
#import "GADBannerView.h"
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
	
//#warning Remove
//	return;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		if (![ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID].purchased) {
			self.gadBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait origin:CGPointMake(0, 0)];
			self.gadBannerView.adSize = kGADAdSizeSmartBannerPortrait;
			self.gadBannerView.rootViewController = self;
			self.gadBannerView.adUnitID = @"ca-app-pub-0434787749004673/2607342948";
			self.gadBannerView.delegate = self;
			
			GADRequest *request = [GADRequest request];
			request.testDevices = @[GAD_SIMULATOR_ID];
			[self.gadBannerView loadRequest:request];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidRemoveAdds:) name:NCApplicationDidRemoveAddsNotification object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
		}
	});
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

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
	self.bannerView.intrinsicContentSize = CGSizeFromGADAdSize(self.gadBannerView.adSize);
	[self.bannerView invalidateIntrinsicContentSize];
	if (!self.gadBannerView.superview) {
		[self.bannerView addSubview:self.gadBannerView];
	}
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	if (self.gadBannerView.superview) {
		[self.gadBannerView removeFromSuperview];
		self.bannerView.intrinsicContentSize = CGSizeZero;
		[self.bannerView invalidateIntrinsicContentSize];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) applicationDidBecomeActive:(NSNotification*) notification {
	if (self.gadBannerView.superview && [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID].purchased) {
		[self.gadBannerView removeFromSuperview];
		self.bannerView.intrinsicContentSize = CGSizeZero;
		[self.bannerView invalidateIntrinsicContentSize];
		self.gadBannerView = nil;
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
}

@end

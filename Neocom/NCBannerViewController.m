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
	
	if (![ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID].purchased) {
		self.gadBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:CGPointMake(0, 0)];
		self.gadBannerView.adSize = kGADAdSizeBanner;
		self.gadBannerView.rootViewController = self;
		self.gadBannerView.adUnitID = @"ca-app-pub-0434787749004673/2607342948";
		self.gadBannerView.delegate = self;
		
		GADRequest *request = [GADRequest request];
		request.testDevices = @[GAD_SIMULATOR_ID];
		[self.gadBannerView loadRequest:request];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidRemoveAdds:) name:NCApplicationDidRemoveAddsNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
	self.bannerView.intrinsicContentSize = self.gadBannerView.adSize.size;
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

#pragma mark - Private

- (void) applicationDidRemoveAdds:(NSNotification*) notification {
	if (self.gadBannerView.superview) {
		[self.gadBannerView removeFromSuperview];
		self.bannerView.intrinsicContentSize = CGSizeZero;
		[self.bannerView invalidateIntrinsicContentSize];
	}
	self.gadBannerView = nil;
}

@end

//
//  EVEUniverseAppDelegate.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/30/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "AdWhirlView.h"
#import "EUOperationQueue.h"
#import "GADBannerView.h"
#import "EVEAccountStorage.h"

@class EVEAccount;
@class EVESkillTree;
@interface EVEUniverseAppDelegate : NSObject <UIApplicationDelegate, /*AdWhirlDelegate, */SKPaymentTransactionObserver, GADBannerViewDelegate> {
    UIWindow *window;
	UIViewController *controller;
	UIViewController *loadingViewController;
	EVEAccount *currentAccount;
	EUOperationQueue *sharedQueue;
	EVEAccountStorage *sharedAccountStorage;
	BOOL inAppStatus;
	BOOL loading;
@private
	//AdWhirlView *adView;
	GADBannerView *adView;
	NSOperationQueue *updateNotificationsQueue;
	NSOperation *updateNotificationsOperation;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;
@property (nonatomic, retain) IBOutlet UIViewController *loadingViewController;
@property (nonatomic, retain) EVEAccount *currentAccount;
@property (getter=isLoading) BOOL loading;
@property (getter=isInAppStatus) BOOL inAppStatus;
@property (nonatomic, retain) EUOperationQueue *sharedQueue;
@property (nonatomic, retain) EVEAccountStorage *sharedAccountStorage;

@end


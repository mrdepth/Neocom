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

@class EVEAccount;
@class EVESkillTree;
@interface EVEUniverseAppDelegate : NSObject <UIApplicationDelegate, SKPaymentTransactionObserver, GADBannerViewDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UIViewController *controller;
@property (nonatomic, strong) IBOutlet UIViewController *loadingViewController;
@property (nonatomic, strong) EVEAccount *currentAccount;
@property (nonatomic, getter = isInAppStatus) BOOL inAppStatus;
@property (nonatomic, strong) EUOperationQueue *sharedQueue;

@end


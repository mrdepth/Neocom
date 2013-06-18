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
@interface EVEUniverseAppDelegate : NSObject <UIApplicationDelegate, SKPaymentTransactionObserver, GADBannerViewDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;
@property (nonatomic, retain) IBOutlet UIViewController *loadingViewController;
@property (nonatomic, retain) EVEAccount *currentAccount;
@property (nonatomic, getter = isInAppStatus) BOOL inAppStatus;
@property (nonatomic, retain) EUOperationQueue *sharedQueue;
@property (nonatomic, retain) EVEAccountStorage *sharedAccountStorage;

@end


//
//  NCAppDelegate.m
//  Neocom
//
//  Created by Artem Shimanski on 27.11.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import "NCAppDelegate.h"
#import "NCAccountsManager.h"
#import "NCStorage.h"
#import "UIAlertView+Error.h"
#import "UIAlertView+Block.h"
#import "EVEOnlineAPI.h"
#import "NCNotificationsManager.h"
#import "NSString+UUID.h"
#import "NSData+Neocom.h"
#import "NCCache.h"
#import "NCMigrationManager.h"
#import "ASInAppPurchase.h"
#import "NCShipFit.h"
#import "NCFittingShipViewController.h"
#import "NCSideMenuViewController.h"
#import "NCMainMenuViewController.h"

@interface NCAppDelegate()<SKPaymentTransactionObserver>
@property (nonatomic, strong) NCTaskManager* taskManager;
- (void) addAPIKeyWithURL:(NSURL*) url;
- (void) openFitWithURL:(NSURL*) url;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;

- (void) setupAppearance;
- (void) migrateWithCompletionHandler:(void(^)()) completionHandler;
- (void) setupDefaultSettings;
@end

@implementation NCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SettingsNoAds"]) {
		ASInAppPurchase* purchase = [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID];
		purchase.purchased = YES;
		[[NSUserDefaults standardUserDefaults] setValue:nil forKeyPath:@"SettingsNoAds"];
	}

	[self setupAppearance];
	[self setupDefaultSettings];
	
	if (![[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsUDIDKey])
		[[NSUserDefaults standardUserDefaults] setValue:[NSString uuidString] forKey:NCSettingsUDIDKey];

	self.taskManager = [NCTaskManager new];
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	[paymentQueue addTransactionObserver:self];

	__block NSError* error = nil;
	[self migrateWithCompletionHandler:^{
		NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
		NSError* error = nil;
		//[accountsManager addAPIKeyWithKeyID:521 vCode:@"m2jHirH1Zvw4LFXiEhuQWsofkpV1th970oz2XGLYZCorWlO4mRqvwHalS77nKYC1" error:&error];
		//[accountsManager addAPIKeyWithKeyID:519 vCode:@"IiEPrrQTAdQtvWA2Aj805d0XBMtOyWBCc0zE57SGuqinJLKGTNrlinxc6v407Vmf" error:&error];
		//[accountsManager addAPIKeyWithKeyID:661 vCode:@"fNYa9itvXjnU8IRRe8R6w3Pzls1l8JXK3b3rxTjHUkTSWasXMZ08ytWHE0HbdWed" error:&error];
		
		NCAccount* account = nil;
		if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
			UILocalNotification* notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
			NSString* uuid = notification.userInfo[NCSettingsCurrentAccountKey];
			if (uuid)
				account = [NCAccount accountWithUUID:uuid];
		}
		
		if (!account) {
			NSString* uuid = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCurrentAccountKey];
			if (uuid)
				account = [NCAccount accountWithUUID:uuid];
		}
		if (account)
			[NCAccount setCurrentAccount:account];
		
		if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
			[application setMinimumBackgroundFetchInterval:60 * 60 * 4];
	}];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
		
	}];
	
	[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:^(BOOL newData) {
		[[NCCache sharedCache] clearInvalidData];
		[application endBackgroundTask:task];
	}];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSString* scheme = [url scheme];
	if ([scheme isEqualToString:@"eve"]) {
		[self addAPIKeyWithURL:url];
	}
	else if ([scheme isEqualToString:@"fitting"])
		[self openFitWithURL:url];
	return YES;
}

- (void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:^(BOOL newData) {
		completionHandler(newData ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
	}];
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	if (application.applicationState == UIApplicationStateActive) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Neocom" message:notification.alertBody delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
		[alert show];
		application.applicationIconBadgeNumber = 0;
	}
	else if (application.applicationState == UIApplicationStateInactive) {
		NSString* uuid = notification.userInfo[NCSettingsCurrentAccountKey];
		NCAccount* account = nil;
		if (uuid)
			account = [NCAccount accountWithUUID:uuid];
		if (account)
			[NCAccount setCurrentAccount:account];
		
	}
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];
			default:
				break;
		}
	}
}

#pragma mark - Private

- (void) addAPIKeyWithURL:(NSURL*) url {
	NSString *query = [url query];
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	
	if (query) {
		for (NSString *subquery in [query componentsSeparatedByString:@"&"]) {
			NSArray *components = [subquery componentsSeparatedByString:@"="];
			if (components.count == 2) {
				NSString *value = [[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
				value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[properties setValue:value forKey:[[components objectAtIndex:0] lowercaseString]];
			}
		}
	}
	__block NSError* error = nil;
	__block BOOL success = NO;
	[[self taskManager] addTaskWithIndentifier:nil
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 int32_t keyID = [properties[@"keyid"] intValue];
											 NSString* vCode = properties[@"vcode"];
											 NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
											 success = [accountsManager addAPIKeyWithKeyID:keyID vCode:vCode error:&error];

										 }
							 completionHandler:^(NCTask *task) {
								 if (!success) {
									 [[UIAlertView alertViewWithError:error] show];
								 }
								 else {
								 [[UIAlertView alertViewWithTitle:nil
														  message:NSLocalizedString(@"API Key added", nil)
												cancelButtonTitle:NSLocalizedString(@"Ok", nil)
												otherButtonTitles:nil
												  completionBlock:nil
													  cancelBlock:nil] show];
								 }
							 }];
}

- (void) openFitWithURL:(NSURL*) url {
	NSMutableString* dna = [NSMutableString stringWithString:[url absoluteString]];
	[dna replaceOccurrencesOfString:@"fitting://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	[dna replaceOccurrencesOfString:@"fitting:" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	NCShipFit* shipFit = [[NCShipFit alloc] initWithDNA:dna];
	if (shipFit) {
		NCFittingShipViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCFittingShipViewController"];
		controller.fit = shipFit;
		UINavigationController* contentViewController = (UINavigationController*) self.window.rootViewController.sideMenuViewController.contentViewController;
		if ([contentViewController isKindOfClass:[UINavigationController class]])
			[contentViewController pushViewController:controller animated:YES];
		else
			[self.window.rootViewController.sideMenuViewController setContentViewController:controller animated:YES];
	}
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
	ASInAppPurchase* purchase = [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID];
	purchase.purchased = YES;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Thanks for the donation", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
	[[NSNotificationCenter defaultCenter] postNotificationName:NCApplicationDidRemoveAddsNotification object:nil];
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
	ASInAppPurchase* purchase = [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID];
	purchase.purchased = YES;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Your donation status has been restored", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
	[[NSNotificationCenter defaultCenter] postNotificationName:NCApplicationDidRemoveAddsNotification object:nil];
	[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [[UIAlertView alertViewWithError:transaction.error] show];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) setupAppearance {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
		[[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
		[[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												forState:UIControlStateNormal
											  barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												forState:UIControlStateHighlighted
											  barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundDone.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												forState:UIControlStateNormal
												   style:UIBarButtonItemStyleDone
											  barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundDoneSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												forState:UIControlStateHighlighted
												   style:UIBarButtonItemStyleDone
											  barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"buttonBackNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 6)]
														  forState:UIControlStateNormal
														barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"buttonBackSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 6)]
														  forState:UIControlStateHighlighted
														barMetrics:UIBarMetricsDefault];
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBar.png"] forBarMetrics:UIBarMetricsDefault];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
		[[UITableView appearance] setSeparatorColor:[UIColor darkGrayColor]];
		[[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar.png"]];
		[[UISearchBar appearance] setSearchFieldBackgroundImage:[[UIImage imageNamed:@"textFieldBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 17, 0, 17)] forState:UIControlStateNormal];
		[[UISearchBar appearance] setScopeBarBackgroundImage:[UIImage imageNamed:@"toolbar.png"]];
		
		
		[[UISegmentedControl appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												   forState:UIControlStateNormal
												 barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundSelected.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
												   forState:UIControlStateSelected
												 barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setDividerImage:[[UIImage imageNamed:@"segmentedControlDivider.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 0, 4, 0)]
									 forLeftSegmentState:UIControlStateNormal
									   rightSegmentState:UIControlStateSelected
											  barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setDividerImage:[[UIImage imageNamed:@"segmentedControlDivider.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 0, 4, 0)]
									 forLeftSegmentState:UIControlStateSelected
									   rightSegmentState:UIControlStateNormal
											  barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setDividerImage:[[UIImage imageNamed:@"segmentedControlDivider.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 0, 4, 0)]
									 forLeftSegmentState:UIControlStateNormal
									   rightSegmentState:UIControlStateNormal
											  barMetrics:UIBarMetricsDefault];
		[[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
	}
}

- (void) migrateWithCompletionHandler:(void(^)()) completionHandler {
	__block NSError* error = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [NCMigrationManager migrateWithError:&error];
										 }
							 completionHandler:^(NCTask *task) {
								 if (error) {
									 [[UIAlertView alertViewWithTitle:NSLocalizedString(@"Error", nil)
															  message:[error localizedDescription]
													cancelButtonTitle:NSLocalizedString(@"Discard", nil)
													otherButtonTitles:@[NSLocalizedString(@"Retry", nil)]
													  completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
														  if (selectedButtonIndex != alertView.cancelButtonIndex)
															  [self migrateWithCompletionHandler:completionHandler];
														  else {
															  NSFileManager* fileManager = [NSFileManager defaultManager];
															  NSString* documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
															  for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:documents error:nil]) {
																  [fileManager removeItemAtPath:[documents stringByAppendingPathComponent:fileName] error:nil];
															  }
															  completionHandler();
														  }
													  } cancelBlock:^{
														  
													  }] show];
								 }
								 else {
									 completionHandler();
								 }
							 }];
}

- (void) setupDefaultSettings {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults valueForKeyPath:NCSettingsSkillQueueNotificationTimeKey])
		[defaults setInteger:NCNotificationsManagerSkillQueueNotificationTimeAll forKey:NCSettingsSkillQueueNotificationTimeKey];
	if (![defaults valueForKeyPath:NCSettingsMarketPricesMonitorKey])
		[defaults setInteger:NCMarketPricesMonitorNone forKey:NCSettingsMarketPricesMonitorKey];
}

@end

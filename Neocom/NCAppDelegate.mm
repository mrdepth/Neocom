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
#import <EVEAPI/EVEAPI.h>
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
#import "NCDatabaseTypeInfoViewController.h"
#import "Flurry.h"
#import "NCAPIKeyAccessMaskViewController.h"
#import "NCShoppingList.h"
#import "NCSplashScreenViewController.h"
#import "NCSkillPlanViewController.h"
#import "NCPriceManager.h"



static NSUncaughtExceptionHandler* handler;

void uncaughtExceptionHandler(NSException* exception) {
	for (NSString* symbol in exception.callStackSymbols) {
		if ([symbol containsString:@"CoreData"]) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CoreDataException"];
			break;
		}
	}
	if (handler) {
		handler(exception);
	}
}

@interface NCAppDelegate()<SKPaymentTransactionObserver, UISplitViewControllerDelegate>
@property (nonatomic, strong) NCTaskManager* taskManager;
- (void) addAPIKeyWithURL:(NSURL*) url;
- (void) openFitWithURL:(NSURL*) url;
- (void) openSkillPlanWithURL:(NSURL*) url;
- (void) showTypeInfoWithURL:(NSURL*) url;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;

- (void) setupAppearance;
- (void) migrateWithCompletionHandler:(void(^)()) completionHandler;
- (void) setupDefaultSettings;

- (void) askToUseCloudWithCompletionHandler:(void(^)(BOOL useCloud)) completionHandler;
- (void) askToTransferDataWithCompletionHandler:(void(^)(BOOL transfer)) completionHandler;
- (void) ubiquityIdentityDidChange:(NSNotification*) notification;
@end

@implementation NCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//#warning Enable Flurry
#if !TARGET_OS_SIMULATOR
	[Flurry setCrashReportingEnabled:YES];
	[Flurry startSession:@"DP6GYKKHQVCR2G6QPJ33"];
#endif

//	handler = NSGetUncaughtExceptionHandler();
//	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

	/*if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SettingsNoAds"]) {
		ASInAppPurchase* purchase = [ASInAppPurchase inAppPurchaseWithProductID:NCInAppFullProductID];
		purchase.purchased = YES;
		[[NSUserDefaults standardUserDefaults] setValue:nil forKeyPath:@"SettingsNoAds"];
	}*/

	[self setupAppearance];
	[self setupDefaultSettings];
	
	if (![[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsUDIDKey])
		[[NSUserDefaults standardUserDefaults] setValue:[NSString uuidString] forKey:NCSettingsUDIDKey];
	
	if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert
																						categories:nil]];
		
	}

	self.taskManager = [NCTaskManager new];
	SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
	[paymentQueue addTransactionObserver:self];

	[self migrateWithCompletionHandler:^{
		id cloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
		
		if (cloudToken && [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey]) {
		}


		void (^loadAccount)() = ^() {
			NSString* uuidFromNotifications = nil;
			if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
				UILocalNotification* notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
				uuidFromNotifications = notification.userInfo[NCSettingsCurrentAccountKey];
			}
			
			NSString* uuidFromDefaults = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCurrentAccountKey];
			if (uuidFromNotifications || uuidFromDefaults) {
				NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
				[storageManagedObjectContext performBlock:^{
					NCAccount* account;
					if (uuidFromNotifications)
						account = [storageManagedObjectContext accountWithUUID:uuidFromNotifications];
					if (!account && uuidFromDefaults)
						account = [storageManagedObjectContext accountWithUUID:uuidFromDefaults];
					if (account)
						dispatch_async(dispatch_get_main_queue(), ^{
							[NCAccount setCurrentAccount:account];
						});
				}];
			}
			
			if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
				[application setMinimumBackgroundFetchInterval:60 * 60 * 4];
			[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
		};

		void (^initStorage)(BOOL) = ^(BOOL useCloud) {
			if (!useCloud) {
				NCStorage* storage = [[NCStorage alloc] initLocalStorage];
				[NCStorage setSharedStorage:storage];
				NCAccountsManager* accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
				[NCAccountsManager setSharedManager:accountsManager];
				loadAccount();
			}
			else {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					NCStorage* storage = [[NCStorage alloc] initCloudStorage];
					if (!storage)
						storage = [[NCStorage alloc] initLocalStorage];
					
					[NCStorage setSharedStorage:storage];
					NCAccountsManager* accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
					[NCAccountsManager setSharedManager:accountsManager];

					dispatch_async(dispatch_get_main_queue(), ^{
						loadAccount();
					});
				});
			}
		};
		
		if (cloudToken) {
			if (![[NSUserDefaults standardUserDefaults] valueForKeyPath:NCSettingsUseCloudKey]) {
				[self askToUseCloudWithCompletionHandler:initStorage];
			}
			else
				initStorage([[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey]);
		}
		else
			initStorage(NO);
	}];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ubiquityIdentityDidChange:) name:NSUbiquityIdentityDidChangeNotification object:nil];
	
	UISplitViewController* controller = (UISplitViewController*) self.window.rootViewController;
	if ([controller isKindOfClass:[UISplitViewController class]]) {
		controller.delegate = self;
	}

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[[NCCache sharedCache] clearInvalidData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	application.applicationIconBadgeNumber = 0;
	[self reconnectStoreIfNeeded];
	
	UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
		
	}];
	
	[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:^(BOOL newData) {
		[application endBackgroundTask:task];
	}];
	
	[[NCPriceManager sharedManager] updateIfNeeded];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString* scheme = [url scheme];
		if ([scheme isEqualToString:@"eve"]) {
			[self addAPIKeyWithURL:url];
		}
		else if ([scheme isEqualToString:@"fitting"])
			[self openFitWithURL:url];
		else if ([scheme isEqualToString:@"file"]) {
			if ([[url pathExtension] compare:@"emp" options:NSCaseInsensitiveSearch] == NSOrderedSame)
				[self openSkillPlanWithURL:url];
		}
		else if ([scheme isEqualToString:@"showinfo"]) {
			[self showTypeInfoWithURL:url];
		}
		else if ([scheme isEqualToString:@"ncaccount"]) {
			NSMutableString* uuid = [NSMutableString stringWithString:[url absoluteString]];
			[uuid replaceOccurrencesOfString:@"ncaccount://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, uuid.length)];
			[uuid replaceOccurrencesOfString:@"ncaccount:" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, uuid.length)];
			if (uuid) {
				NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
				[storageManagedObjectContext performBlock:^{
					NCAccount* account = [storageManagedObjectContext accountWithUUID:uuid];
					if (account)
						dispatch_async(dispatch_get_main_queue(), ^{
							[NCAccount setCurrentAccount:account];
						});
				}];
			}
		}
	});
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
		if (uuid) {
			NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
			[storageManagedObjectContext performBlock:^{
				NCAccount* account = [storageManagedObjectContext accountWithUUID:uuid];
				if (account)
					dispatch_async(dispatch_get_main_queue(), ^{
						[NCAccount setCurrentAccount:account];
					});
			}];
		}
		
	}
}

- (void) reconnectStoreIfNeeded {
/*	NCStorage* storage = [NCStorage sharedStorage];
	if (storage) {
		id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
		
		id lastCloudToken = nil;
		NSData *tokenData = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCloudTokenKey];
		if (tokenData)
			lastCloudToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
		
		BOOL useCloud = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsUseCloudKey];
		
		BOOL needsAsk = ![[NSUserDefaults standardUserDefaults] valueForKeyPath:NCSettingsUseCloudKey];
		BOOL tokenChanged = currentCloudToken != lastCloudToken && ![currentCloudToken isEqual:lastCloudToken];
		BOOL settingsChanged = (storage.storageType == NCStorageTypeCloud && !useCloud)  || (storage.storageType == NCStorageTypeFallback && (useCloud && currentCloudToken));
		
		void (^initStorage)(BOOL) = ^(BOOL useCloud) {
			
			if (!useCloud || !currentCloudToken) {
				[NCAccount setCurrentAccount:nil];
				[NCShoppingList setCurrentShoppingList:nil];
				
				NCStorage* storage = [NCStorage fallbackStorage];
				[NCStorage setSharedStorage:storage];
				NCAccountsManager* accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
				[NCAccountsManager setSharedManager:accountsManager];
				[[NSNotificationCenter defaultCenter] postNotificationName:NCStorageDidChangeNotification object:storage userInfo:nil];
				[[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
				[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
			}
			else {
				__block NCStorage* storage = nil;
				__block NCAccountsManager* accountsManager = nil;
				[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													 title:NCTaskManagerDefaultTitle
													 block:^(NCTask *task) {
														 storage = [NCStorage cloudStorage];
														 if (!storage)
															 storage = [NCStorage fallbackStorage];
														 accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
													 }
										 completionHandler:^(NCTask *task) {
											 [NCAccount setCurrentAccount:nil];
											 [NCShoppingList setCurrentShoppingList:nil];
											 
											 [NCStorage setSharedStorage:storage];
											 [NCAccountsManager setSharedManager:accountsManager];
											 
											 NCStorage* storage = [NCStorage sharedStorage];
											 if (storage.storageType == NCStorageTypeCloud && ![[NSUserDefaults standardUserDefaults] valueForKey:@"NCSettingsMigratedToCloudKey"]) {
												 [self askToTransferDataWithCompletionHandler:^(BOOL transfer) {
													 if (transfer)
														 [[NCStorage sharedStorage] transferDataFromFallbackToCloud];
												 }];
											 }
											 [[NSNotificationCenter defaultCenter] postNotificationName:NCStorageDidChangeNotification object:storage userInfo:nil];
											 [[NCNotificationsManager sharedManager] setNeedsUpdateNotifications];
											 [[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
										 }];
			}
		};
		
		if (needsAsk) {
			[self askToUseCloudWithCompletionHandler:^(BOOL useCloud) {
				initStorage(useCloud);
			}];
		}
		else if ((useCloud && tokenChanged) || settingsChanged) {
			initStorage(useCloud);
		}
	}*/
}

- (UIInterfaceOrientationMask) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return UIInterfaceOrientationMaskAll;
	}
	else {
		if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
			return UIInterfaceOrientationMaskPortrait;
		else {
			if ([self.window respondsToSelector:NSSelectorFromString(@"_traitCollectionWhenRotated")]) {
				UITraitCollection* tc1 = [self.window traitCollection];
				UITraitCollection* tc2 = [self.window valueForKeyPath:@"_traitCollectionWhenRotated"];
				if (self.window) {
					return (tc1.horizontalSizeClass == UIUserInterfaceSizeClassRegular && tc1.verticalSizeClass == UIUserInterfaceSizeClassCompact) ||
					(tc2.horizontalSizeClass == UIUserInterfaceSizeClassRegular && tc2.verticalSizeClass == UIUserInterfaceSizeClassCompact)
					? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
				}
			}
		}
	}
	return UIInterfaceOrientationMaskPortrait;
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

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController*) secondaryViewController viewControllers][0] isKindOfClass:[NCSplashScreenViewController class]])
			return YES;
	}
	return NO;
}

- (void) splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
	if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
		[[svc.viewControllers[1] viewControllers][0] navigationItem].leftBarButtonItem = nil;
	}
	else
		[[svc.viewControllers[1] viewControllers][0] navigationItem].leftBarButtonItem = svc.displayModeButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
	barButtonItem.image = [UIImage imageNamed:@"menuIcon.png"];
	UINavigationController* navigationController = svc.viewControllers[1];
	if ([navigationController isKindOfClass:[UINavigationController class]]) {
		[[navigationController.viewControllers[0] navigationItem] setLeftBarButtonItem:barButtonItem animated:YES];
	}
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	UINavigationController* navigationController = svc.viewControllers[1];
	if ([navigationController isKindOfClass:[UINavigationController class]]) {
		[[navigationController.viewControllers[0] navigationItem] setLeftBarButtonItem:nil animated:YES];
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
	
	int32_t keyID = [properties[@"keyid"] intValue];
	NSString* vCode = properties[@"vcode"];

	if (keyID > 0 && vCode.length > 0)
	[[NCAccountsManager sharedManager] addAPIKeyWithKeyID:keyID vCode:vCode completionBlock:^(NSArray *accounts, NSError *error) {
		if (error) {
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
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UISplitViewController* splitViewController = (UISplitViewController*) self.window.rootViewController;
			UINavigationController* navigationController = splitViewController.viewControllers[1];
			
			if ([navigationController isKindOfClass:[UINavigationController class]]) {
				[navigationController dismissViewControllerAnimated:YES completion:nil];
				[navigationController pushViewController:controller animated:YES];
			}
			else {
				UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
				navigationController.navigationBar.barStyle = UIBarStyleBlack;
				[splitViewController setViewControllers:@[splitViewController.viewControllers[0], navigationController]];
			}

		}
		else {
			UINavigationController* navigationController = (UINavigationController*) self.window.rootViewController.childViewControllers[0];
			if ([navigationController isKindOfClass:[UINavigationController class]]) {
				[navigationController dismissViewControllerAnimated:YES completion:nil];
				[navigationController pushViewController:controller animated:YES];
			}
		}
	}
}

- (void) openSkillPlanWithURL:(NSURL*) url {

	NCAccount* currentAccount = [NCAccount currentAccount];
	if (!currentAccount || currentAccount.accountType != NCAccountTypeCharacter) {
		[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Skill Plan Import", nil)
								 message:NSLocalizedString(@"You should select the Character first to import Skill Plan", nil)
					   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
					   otherButtonTitles:nil
						 completionBlock:nil
							 cancelBlock:nil] show];
	}
	else {
		NSData* data = [[NSData dataWithContentsOfURL:url] uncompressedData];
		NSString* name = [[url lastPathComponent] stringByDeletingPathExtension];
		
		if (data) {
			if (!name)
				name = NSLocalizedString(@"Skill Plan", nil);
			UINavigationController* navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCSkillPlanViewController"];
			NCSkillPlanViewController* controller = navigationController.viewControllers[0];
			controller.xmlData = data;
			controller.skillPlanName = name;
			[self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
		}
	}
	[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
}

- (void) showTypeInfoWithURL:(NSURL*) url {
	NSMutableString* resourceSpecifier = [[url resourceSpecifier] mutableCopy];
	if ([resourceSpecifier hasPrefix:@"//"])
		[resourceSpecifier replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
	
	NSArray* components = [resourceSpecifier pathComponents];
	
	NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
	
	if (components.count > 0) {
		NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:[components[0] intValue]];
		if (type && type.attributesDictionary.count > 0) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UIViewController* presentedViewController = nil;
				for (presentedViewController = self.window.rootViewController; presentedViewController.presentedViewController; presentedViewController = presentedViewController.presentedViewController);
				if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
					NCDatabaseTypeInfoViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewController"];
					controller.typeID = [type objectID];
					[(UINavigationController*) presentedViewController pushViewController:controller animated:YES];
				}
				else {
					UINavigationController* navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewNavigationController"];
					navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
					NCDatabaseTypeInfoViewController* controller = navigationController.viewControllers[0];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)];
					controller.typeID = [type objectID];
					[presentedViewController presentViewController:navigationController animated:YES completion:nil];
				}
			}
			else {
				NCDatabaseTypeInfoViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewController"];
				controller.typeID = [type objectID];

				UINavigationController* navigationController = (UINavigationController*) self.window.rootViewController.childViewControllers[0];
				if ([navigationController isKindOfClass:[UINavigationController class]])
					[navigationController pushViewController:controller animated:YES];
			}
		}
		else {
			NSURL* url = [NSURL URLWithString:resourceSpecifier];
			if (url) {
				NSManagedObjectContext* storageManagedObjectContext = [[NCAccountsManager sharedManager] storageManagedObjectContext];
				[storageManagedObjectContext performBlock:^{
					NSManagedObjectID* objectID = [storageManagedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
					if (objectID) {
						NCAccount* account = (NCAccount*) [storageManagedObjectContext existingObjectWithID:objectID error:nil];
						if ([account isKindOfClass:[NCAccount class]]) {
							dispatch_async(dispatch_get_main_queue(), ^{
								if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
									UINavigationController* navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCAPIKeyAccessMaskViewController"];
									navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
									NCAPIKeyAccessMaskViewController* controller = navigationController.viewControllers[0];
									controller.account = account;
									controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)];
									[self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
								}
								else {
									NCAPIKeyAccessMaskViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCAPIKeyAccessMaskViewController"];
									
									controller.account = account;
									
									UINavigationController* navigationController = (UINavigationController*) self.window.rootViewController.childViewControllers[0];
									if ([navigationController isKindOfClass:[UINavigationController class]])
										[navigationController pushViewController:controller animated:YES];
								}
							});
						}
					}
				}];
			}
		}
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
																  if ([fileName isEqualToString:@"Inbox"])
																	  continue;
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

- (void) askToUseCloudWithCompletionHandler:(void(^)(BOOL useCloud)) completionHandler {
	[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Choose Storage Option", nil)
							 message:NSLocalizedString(@"Should documents be stored in iCloud and available on all your devices?", nil)
				   cancelButtonTitle:NSLocalizedString(@"Local Only", nil)
				   otherButtonTitles:@[NSLocalizedString(@"iCloud", nil)]
					 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
						 BOOL useCloud = selectedButtonIndex != alertView.cancelButtonIndex;
						 [[NSUserDefaults standardUserDefaults] setBool:useCloud
																 forKey:NCSettingsUseCloudKey];
						 completionHandler(useCloud);
					 }
						 cancelBlock:^{
							 completionHandler(NO);
						 }] show];
}

- (void) askToTransferDataWithCompletionHandler:(void(^)(BOOL transfer)) completionHandler {
	[[UIAlertView alertViewWithTitle:nil
							 message:NSLocalizedString(@"Do you want to copy Local Data to iCloud?", nil)
				   cancelButtonTitle:NSLocalizedString(@"No", nil)
				   otherButtonTitles:@[NSLocalizedString(@"Copy", nil)]
					 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
						 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NCSettingsMigratedToCloudKey"];
						 completionHandler(selectedButtonIndex != alertView.cancelButtonIndex);
					 }
						 cancelBlock:^{
							 completionHandler(NO);
						 }] show];
}

- (void) ubiquityIdentityDidChange:(NSNotification*) notification {
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		[self reconnectStoreIfNeeded];
}

@end

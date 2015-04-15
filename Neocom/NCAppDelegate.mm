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
#import "NCDatabaseTypeInfoViewController.h"
#import "Flurry.h"
#import "NCAPIKeyAccessMaskViewController.h"
#import "NCShoppingList.h"

@interface NCAppDelegate()<SKPaymentTransactionObserver>
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
#if !TARGET_IPHONE_SIMULATOR
	[Flurry setCrashReportingEnabled:YES];
	[Flurry startSession:@"DP6GYKKHQVCR2G6QPJ33"];
#endif
	
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

//	__block NSError* error = nil;
	[self migrateWithCompletionHandler:^{
//		NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
//		NSError* error = nil;
//		[accountsManager addAPIKeyWithKeyID:521 vCode:@"m2jHirH1Zvw4LFXiEhuQWsofkpV1th970oz2XGLYZCorWlO4mRqvwHalS77nKYC1" error:&error];
//		[accountsManager addAPIKeyWithKeyID:519 vCode:@"IiEPrrQTAdQtvWA2Aj805d0XBMtOyWBCc0zE57SGuqinJLKGTNrlinxc6v407Vmf" error:&error];
//		[accountsManager addAPIKeyWithKeyID:661 vCode:@"fNYa9itvXjnU8IRRe8R6w3Pzls1l8JXK3b3rxTjHUkTSWasXMZ08ytWHE0HbdWed" error:&error];
		
		id cloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];


		void (^loadAccount)() = ^() {
			NCStorage* storage = [NCStorage sharedStorage];
			NCAccount* account = nil;
			if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
				UILocalNotification* notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
				NSString* uuid = notification.userInfo[NCSettingsCurrentAccountKey];
				if (uuid)
					account = [storage accountWithUUID:uuid];
			}
			
			if (!account) {
				NSString* uuid = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsCurrentAccountKey];
				if (uuid)
					account = [storage accountWithUUID:uuid];
			}
			if (account)
				[NCAccount setCurrentAccount:account];
			
			if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
				[application setMinimumBackgroundFetchInterval:60 * 60 * 4];
			[[NCNotificationsManager sharedManager] updateNotificationsIfNeededWithCompletionHandler:nil];
		};

		void (^initStorage)(BOOL) = ^(BOOL useCloud) {
			if (!useCloud) {
				NCStorage* storage = [NCStorage fallbackStorage];
				[NCStorage setSharedStorage:storage];
				NCAccountsManager* accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
				[NCAccountsManager setSharedManager:accountsManager];
				loadAccount();
			}
			else {
				[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													 title:NCTaskManagerDefaultTitle
													 block:^(NCTask *task) {
														 NCStorage* storage = [NCStorage cloudStorage];
														 if (!storage)
															 storage = [NCStorage fallbackStorage];

														 [NCStorage setSharedStorage:storage];
														 NCAccountsManager* accountsManager = [[NCAccountsManager alloc] initWithStorage:storage];
														 [NCAccountsManager setSharedManager:accountsManager];
													 }
										 completionHandler:^(NCTask *task) {
											 NCStorage* storage = [NCStorage sharedStorage];
											 if (storage.storageType == NCStorageTypeCloud && ![[NSUserDefaults standardUserDefaults] valueForKey:@"NCSettingsMigratedToCloudKey"]) {
												 [self askToTransferDataWithCompletionHandler:^(BOOL transfer) {
													 if (transfer)
														 [[NCStorage sharedStorage] transferDataFromFallbackToCloud];
													 loadAccount();
												 }];
											 }
											 else
												 loadAccount();
										 }];
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

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[[NCStorage sharedStorage] saveContext];
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[NCStorage sharedStorage] saveContext];
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
			NCAccount* account = nil;
			if (uuid)
				account = [[NCStorage sharedStorage] accountWithUUID:uuid];
			if (account)
				[NCAccount setCurrentAccount:account];
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
		NCAccount* account = nil;
		if (uuid)
			account = [[NCStorage sharedStorage] accountWithUUID:uuid];
		if (account)
			[NCAccount setCurrentAccount:account];
		
	}
}

- (void) reconnectStoreIfNeeded {
	NCStorage* storage = [NCStorage sharedStorage];
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
											 NCAccountsManager* accountsManager = [NCAccountsManager sharedManager];
											 if (accountsManager)
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
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UISplitViewController* splitViewController = (UISplitViewController*) self.window.rootViewController;
				[splitViewController.viewControllers[0] performSegueWithIdentifier:@"NCSkillPlanViewController" sender:@{@"name": name, @"data": data}];
			}
			else
				[self.window.rootViewController performSegueWithIdentifier:@"NCSkillPlanViewController" sender:@{@"name": name, @"data": data}];

		}
	}
	[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
}

- (void) showTypeInfoWithURL:(NSURL*) url {
	NSMutableString* resourceSpecifier = [[url resourceSpecifier] mutableCopy];
	if ([resourceSpecifier hasPrefix:@"//"])
		[resourceSpecifier replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
	
	NSArray* components = [resourceSpecifier pathComponents];
	if (components.count > 0) {
		NCDBInvType* type = [NCDBInvType invTypeWithTypeID:[components[0] intValue]];
		if (type && type.attributesDictionary.count > 0) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UIViewController* presentedViewController = nil;
				for (presentedViewController = self.window.rootViewController; presentedViewController.presentedViewController; presentedViewController = presentedViewController.presentedViewController);
				if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
					NCDatabaseTypeInfoViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewController"];
					controller.type = (id) type;
					[(UINavigationController*) presentedViewController pushViewController:controller animated:YES];
				}
				else {
					UINavigationController* navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewNavigationController"];
					navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
					NCDatabaseTypeInfoViewController* controller = navigationController.viewControllers[0];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)];
					controller.type = (id) type;
					[presentedViewController presentViewController:navigationController animated:YES completion:nil];
				}
			}
			else {
				NCDatabaseTypeInfoViewController* controller = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoViewController"];
				controller.type = (id) type;

				UINavigationController* navigationController = (UINavigationController*) self.window.rootViewController.childViewControllers[0];
				if ([navigationController isKindOfClass:[UINavigationController class]])
					[navigationController pushViewController:controller animated:YES];
			}
		}
		else {
			NSURL* url = [NSURL URLWithString:resourceSpecifier];
			if (url) {
				NCStorage* storage = [NCStorage sharedStorage];
				[storage.managedObjectContext performBlock:^{
					NSManagedObjectID* objectID = [storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url];
					if (objectID) {
						NCAccount* account = (NCAccount*) [storage.managedObjectContext existingObjectWithID:objectID error:nil];
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

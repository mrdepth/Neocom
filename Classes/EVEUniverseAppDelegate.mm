//
//  EVEUniverseAppDelegate.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 8/30/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"
#import "Globals.h"
#import "EVEOnlineAPI.h"
#import "UIAlertView+Error.h"
#import "UIImageView+GIF.h"
#import "EUMailBox.h"
#import "EUActivityView.h"
#import "FittingViewController.h"
#import "ShipFit.h"
#import "EUStorage.h"
#import "EUMigrationManager.h"
#import "UIAlertView+Block.h"
#import "NSString+UUID.h"
#import "UIColor+NSNumber.h"
#import "EVEAccountsManager.h"
#import "FitCharacter.h"
#import "appearance.h"
#import "NCURLCache.h"
#import "Flurry.h"

#define NSURLCacheDiskCapacity (1024*1024*50)
#define NSURLCacheMemoryCapacity (1024*1024*50)

@interface UISearchBar(Neocom)
@property (nonatomic, strong) UIColor* textColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, readonly) UITextField* searchField;
@end

@implementation UISearchBar(Neocom)

- (UITextField*) searchField {
	return [self valueForKey:@"_searchField"];
}

- (void) setTextColor:(UIColor *)textColor {
	self.searchField.textColor = textColor;
}

- (UIColor*) textColor {
	return self.searchField.textColor;
}

@end

@interface UITableView(Neocom)

- (void) setSeparatorStyleAppearance: (UITableViewCellSeparatorStyle)separatorStyle UI_APPEARANCE_SELECTOR;

@end

@implementation UITableView(Neocom)

- (void) setSeparatorStyleAppearance: (UITableViewCellSeparatorStyle)separatorStyle {
	self.separatorStyle = separatorStyle;
}

@end

@interface UINavigationBar(iScanner)
- (void) setTranslucentAppearance:(NSInteger)translucent UI_APPEARANCE_SELECTOR;
@end

@implementation UINavigationBar(iScanner)

- (void) setTranslucentAppearance:(NSInteger)translucent {
	self.translucent = translucent;
}

@end


@interface EVEUniverseAppDelegate()<GADBannerViewDelegate>
@property (nonatomic, strong) GADBannerView *adView;
@property (nonatomic, strong) NSOperationQueue *updateNotificationsQueue;
@property (nonatomic, strong) NSOperation *updateNotificationsOperation;
@property (nonatomic, assign, getter = isInitializationFinished) BOOL initializationFinished;
@property (nonatomic, strong) NSDate* resignActiveTime;

- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) updateNotifications;
- (void) addAPIKeyWithURL:(NSURL*) url;
- (void) openFitWithURL:(NSURL*) url;
- (void) configureCloudWithCompletionHandler:(void(^)()) completionHandler;
- (void) setupAppearance;
- (void) accountDidSelect:(NSNotification*) notification;
- (void) removeAds;
@end

@implementation EVEUniverseAppDelegate
@synthesize inAppStatus = _inAppStatus;

#pragma mark -
#pragma mark Application lifecycle


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[Flurry startSession:@"DP6GYKKHQVCR2G6QPJ33"];
	NCURLCache* cache = [[NCURLCache alloc] initWithMemoryCapacity:NSURLCacheMemoryCapacity diskCapacity:NSURLCacheDiskCapacity diskPath:@"NCURLCache"];
	[NSURLCache setSharedURLCache:cache];
	[EVECachedURLRequest setOfflineMode:[[NSUserDefaults standardUserDefaults] boolForKey:SettingsOfflineMode]];
	[self setupAppearance];
	
	
	//[[EUStorage sharedStorage] managedObjectContext];
	
	/*NSPersistentStoreCoordinator *coordinator = [[EUStorage sharedStorage] persistentStoreCoordinator];
    if (coordinator != nil) {
		NSManagedObjectContext* managedObjectContext1 = [[EUStorage sharedStorage] managedObjectContext];
        NSManagedObjectContext* managedObjectContext2 = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [managedObjectContext2 setPersistentStoreCoordinator:coordinator];
		
		ShipFit* fit1;
		ShipFit* fit2;

		{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:managedObjectContext1];
			[fetchRequest setEntity:entity];
			
			
			NSError *error = nil;
			NSArray *fetchedObjects = [managedObjectContext1 executeFetchRequest:fetchRequest error:&error];
			fit1 = [fetchedObjects objectAtIndex:0];
			[fetchRequest release];
		}
		
		{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:managedObjectContext2];
			[fetchRequest setEntity:entity];
			
			
			NSError *error = nil;
			NSArray *fetchedObjects = [managedObjectContext2 executeFetchRequest:fetchRequest error:&error];
			fit2 = [fetchedObjects objectAtIndex:0];
			[fetchRequest release];
		}
		
		NSLog(@"%@", fit1.fitName);
		fit1.fitName = @"Fit11";
		fit2.fitName = @"Fit22";
		NSError* error  = nil;
		[managedObjectContext1 save:&error];
		NSLog(@"%@", error);
		[managedObjectContext2 save:&error];
		NSLog(@"%@", error);
		[managedObjectContext2 refreshObject:fit2 mergeChanges:NO];
		error = nil;
		[managedObjectContext2 save:&error];
		NSLog(@"%@ %@", error, fit2.fitName);
    }*/

	
	//[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNoAds];
	
    // Override point for customization after application launch.
	
	if (![[NSUserDefaults standardUserDefaults] valueForKey:SettingsUDID])
		[[NSUserDefaults standardUserDefaults] setValue:[NSString uuidString] forKey:SettingsUDID];
	
	self.updateNotificationsQueue = [[NSOperationQueue alloc] init];

	UILocalNotification *notification = [launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	if (notification) {
		[[NSUserDefaults standardUserDefaults] setObject:notification.userInfo[SettingsCurrentCharacterID] forKey:SettingsCurrentCharacterID];
	}
	
	[self.window addSubview:self.controller.view];
	[self.window makeKeyAndVisible];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"disableActivityIndicator"]]) {
		EUActivityView* activityView = [[EUActivityView alloc] initWithFrame:self.window.rootViewController.view.bounds];
		[self.window addSubview:activityView];
	}
	
	
	self.loadingViewController.view.alpha = 0;
	[self.window addSubview:self.loadingViewController.view];
	self.loadingViewController.view.center = CGPointMake(self.window.frame.size.width / 2, self.window.frame.size.height / 2);
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsNoAds]) {
		CGSize gadSize = CGSizeMake(320, 50);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UISplitViewController* splitViewController = (UISplitViewController*) self.controller;
			CGRect frame = [[[splitViewController.viewControllers objectAtIndex:0] view] frame];
			self.adView = [[GADBannerView alloc] initWithFrame:CGRectMake(0, frame.size.height - gadSize.height, gadSize.width, gadSize.height)];
			self.adView.rootViewController = self.controller;
			self.adView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			[[[splitViewController.viewControllers objectAtIndex:0] view] addSubview:self.adView];
		}
		else {
			CGRect frame = [[UIScreen mainScreen] bounds];
			frame.origin.y = frame.size.height - gadSize.height;
			frame.size.height = gadSize.height;
			self.adView = [[GADBannerView alloc] initWithFrame:frame];
			self.adView.rootViewController = self.controller;
			//[self.controller.view addSubview:self.adView];
		}
		//self.adView.adUnitID = @"a14d501062a8c09";
		self.adView.adUnitID = @"3822eeab0e184c8f";
		self.adView.delegate = self;
		GADRequest *request = [GADRequest request];
		request.testDevices = @[GAD_SIMULATOR_ID];
		[self.adView loadRequest:request];
		
	}
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	
	EUOperation* operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+migrate" name:NSLocalizedString(@"Initializing storage", nil)];
	[operation addExecutionBlock:^{
		EUMigrationManager* migrationManager = [[EUMigrationManager alloc] init];
		[migrationManager migrateIfNeeded];
	}];
	
	[operation setCompletionBlockInMainThread:^{
		self.initializationFinished = YES;
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
	
	
	NSInteger characterID = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsCurrentCharacterID];
	__block EVEAccount* account = nil;
	EVEAccountsManager* manager = [[EVEAccountsManager alloc] init];
	EUOperation* loadingAccountsOperation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+loadingAccounts" name:NSLocalizedString(@"Loading Accounts", nil)];
	[loadingAccountsOperation addExecutionBlock:^{
		[manager reload];
		account = [manager accountWithCharacterID:characterID];
		[account reload];
	}];
	
	[loadingAccountsOperation setCompletionBlockInMainThread:^{
		[EVEAccountsManager setSharedManager:manager];
		if (account)
			[EVEAccount setCurrentAccount:account];
		[self updateNotifications];
	}];
	
	[loadingAccountsOperation addDependency:operation];
	[[EUOperationQueue sharedQueue] addOperation:loadingAccountsOperation];

	
	[self configureCloudWithCompletionHandler:^{
	}];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidSelect:) name:EVEAccountDidSelectNotification object:nil];

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	self.resignActiveTime = [NSDate date];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	if([self.resignActiveTime timeIntervalSinceNow] < -60 * 30) {
		EVEAccount* account = [EVEAccount currentAccount];
		if (account) {
			EUOperation* operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+applicationDidBecomeActive" name:NSLocalizedString(@"Updating Account Information", nil)];
			[operation addExecutionBlock:^{
				[account reload];
			}];
			
			[operation setCompletionBlockInMainThread:^{
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		[self updateNotifications];
	}
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	if (application.applicationState == UIApplicationStateActive) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Neocom" message:notification.alertBody delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
		[alert show];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:notification.userInfo[SettingsCurrentCharacterID] forKey:SettingsCurrentCharacterID];
	}
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSString* scheme = [url scheme];
	if ([scheme isEqualToString:@"eve"])
		[self addAPIKeyWithURL:url];
	else if ([scheme isEqualToString:@"fitting"])
		[self openFitWithURL:url];
	return YES;
}

- (void) setCurrentAccount: (EVEAccount*) value {
	if (value != _currentAccount) {
		_currentAccount = value;
	}
	if (_currentAccount) {
		[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountDidSelectNotification object:_currentAccount];
	}
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:EVEAccountDidSelectNotification object:_currentAccount];
/*	if (!_currentAccount)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:SettingsCurrentAccount];
	else
		[[NSUserDefaults standardUserDefaults] setObject:[_currentAccount dictionary] forKey:SettingsCurrentAccount];
*/
	if (_currentAccount && ((_currentAccount.charAPIKey.apiKeyInfo.key.accessMask & 49152) == 49152)) { //49152 = NotificationTexts | Notifications
		NSMutableArray* wars = [NSMutableArray array];
		
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+CheckMail" name:NSLocalizedString(@"Checking War Declarations", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^(void) {
			EUMailBox* mailBox = [_currentAccount mailBox];
			NSMutableSet* ids = [NSMutableSet set];
			float n = mailBox.notifications.count + 1;
			float i = 0;
			for (EUNotification* notification in  mailBox.notifications) {
				weakOperation.progress = i++ / n;
				if (!notification.read && (notification.header.typeID == 5 || notification.header.typeID == 27)) {
					NSString* declaredByID = [notification.details.properties valueForKey:@"declaredByID"];
					NSInteger iDeclaredByID = [declaredByID integerValue];
					if (declaredByID && _currentAccount.characterSheet.corporationID != iDeclaredByID && _currentAccount.characterSheet.allianceID != iDeclaredByID)
						[ids addObject:declaredByID];
				}
			}
			if (ids.count > 0) {
				EVECharacterName* charNames = [EVECharacterName characterNameWithIDs:[ids allObjects] error:nil progressHandler:nil];
				
				for (NSString* war in [charNames.characters allValues]) {
					[wars addObject:war];
				}
			}
			weakOperation.progress = 1;
			[mailBox save];
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			if (wars.count > 0) {
				NSString* s = [wars componentsJoinedByString:@", "];
				BOOL multiple = wars.count > 1;
				NSString* message;
				if (multiple)
					message = [NSString stringWithFormat:NSLocalizedString(@"%@ have declared war against you! Fly safe.", nil), s];
				else
					message = [NSString stringWithFormat:NSLocalizedString(@"%@ has declared war against you! Fly safe.", nil), s];
				
				UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:multiple ? NSLocalizedString(@"Declarations of war!", nil) : NSLocalizedString(@"Declaration of war!", nil)
																	message:message
																   delegate:nil
														  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
														  otherButtonTitles:nil];
				[alertView show];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

- (BOOL) isInAppStatus {
	@synchronized(self) {
		return self.inAppStatus;
	}
}

- (void) setInAppStatus:(BOOL)value {
	@synchronized(self) {
		_inAppStatus = value;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.5];
		self.loadingViewController.view.alpha = _inAppStatus ? 1 : 0;
		[UIView commitAnimations];
	}
}

- (EUOperationQueue*) sharedQueue {
	if (!_sharedQueue) {
		_sharedQueue = [[EUOperationQueue alloc] init];
	}
	return _sharedQueue;
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	EVEAccount *account = [EVEAccount currentAccount];
	[account.properties removeAllObjects];
	account.skillPlan = nil;
	account.mailBox = nil;
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


/*#pragma mark AdMobDelegate

- (NSString *)publisherIdForAd:(AdMobView *)adView {
	return @"a14d501062a8c09";
}

- (UIViewController *)currentViewControllerForAd:(AdMobView *)adView {
	return controller;
}

- (UIColor *)adBackgroundColorForAd:(AdMobView *)adView {
	return [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)primaryTextColorForAd:(AdMobView *)adView {
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)secondaryTextColorForAd:(AdMobView *)adView {
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}*/

/*#pragma mark AdWhirlDelegate

- (NSString *)adWhirlApplicationKey {
	return @"a306fe26cc8a440e8ed9d26251aad0ad";
}

- (UIViewController *)viewControllerForPresentingModalView {
	return controller;
}

- (void)adWhirlDidReceiveAd:(AdWhirlView *)adWhirlView {
	adView.hidden = NO;
	[UIView beginAnimations:@"AdWhirlDelegate.adWhirlDidReceiveAd:"
					context:nil];
	[UIView setAnimationDuration:0.7];
	CGSize adSize = [adView actualAdSize];
	CGRect newFrame = adView.frame;
	newFrame.size = adSize;
	newFrame.origin.x = (self.window.bounds.size.width - adSize.width)/ 2;
	newFrame.origin.y = self.window.bounds.size.height - adSize.height;
	adView.frame = newFrame;
	[UIView commitAnimations];
}

- (void)adWhirlDidFailToReceiveAd:(AdWhirlView *)adWhirlView usingBackup:(BOOL)yesOrNo {
	adView.hidden = YES;
}*/

/*- (BOOL)adWhirlTestMode {
	return YES;
}*/

#pragma mark SKPaymentTransactionObserver

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

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
	if (!view.superview) {
		UIView* contentView = [self.window.rootViewController valueForKey:@"navigationTransitionView"];
		CGRect frame = contentView.frame;
		frame.size.height -= view.frame.size.height;
		contentView.frame = frame;
		view.frame = CGRectMake(0, frame.size.height, view.frame.size.width, view.frame.size.height);
		[self.window.rootViewController.view addSubview:view];
	}
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
	adView.hidden = YES;
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
	adView.hidden = NO;
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
	adView.hidden = NO;
}

#pragma mark - Private

- (void) loadAccounts {
	
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNoAds];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[self removeAds];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Thanks for the donation", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNoAds];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[self removeAds];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Your donation status has been restored", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [[UIAlertView alertViewWithError:transaction.error] show];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) updateNotifications {
	[[UIApplication sharedApplication] cancelAllLocalNotifications];

	EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+updateNotifications" name:NSLocalizedString(@"Updating Notifications", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if ([weakOperation isCancelled])
			return;
		EVEAccountsManager* accountsManager = [EVEAccountsManager sharedManager];
		NSArray* accounts = accountsManager.allAccounts;
		float n = accounts.count;
		float i = 0;
		for (EVEAccount* account in accounts) {
			weakOperation.progress = i++ / n;
			if (!account.ignored) {
				if (account.charAPIKey) {
					NSError *error = nil;
					EVESkillQueue *skillQueue = [EVESkillQueue skillQueueWithKeyID:account.charAPIKey.keyID vCode:account.charAPIKey.vCode characterID:account.character.characterID error:&error progressHandler:nil];
					if (!error && skillQueue.skillQueue.count > 0) {
						NSDate *endTime = [[skillQueue.skillQueue lastObject] endTime];
						if (endTime) {
							endTime = [skillQueue localTimeWithServerTime:endTime];
							NSTimeInterval dif = [endTime timeIntervalSinceNow];
							if (dif > 3600 * 24) {
								UILocalNotification *notification = [[UILocalNotification alloc] init];
								notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 24 hours training left.", nil), account.character.characterName];
								notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 24];
								notification.userInfo = @{SettingsCurrentCharacterID: @(account.character.characterID)};
								[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(scheduleLocalNotification:) withObject:notification waitUntilDone:NO];
							}
						}
					}
				}
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (self.updateNotificationsOperation == weakOperation)
			self.updateNotificationsOperation = nil;
	}];
	
	if (self.updateNotificationsOperation)
		[operation addDependency:self.updateNotificationsOperation];
	self.updateNotificationsOperation = operation;
	[self.updateNotificationsQueue addOperation:operation];
}

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
	EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+AddAPIKey" name:NSLocalizedString(@"Adding API Key", nil)];
	__block NSError *error = nil;
	[operation addExecutionBlock:^(void) {
		[[EVEAccountsManager sharedManager] addAPIKeyWithKeyID:[properties[@"keyid"] integerValue] vCode:properties[@"vcode"] error:&error];
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (error) {
			[[UIAlertView alertViewWithError:error] show];
		}
		else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"API Key added", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
			[alertView show];
			//[[NSNotificationCenter defaultCenter] postNotificationName:NotificationAccountStoargeDidChange object:nil];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) openFitWithURL:(NSURL*) url {
	NSMutableString* dna = [NSMutableString stringWithString:[url absoluteString]];
	[dna replaceOccurrencesOfString:@"fitting://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	[dna replaceOccurrencesOfString:@"fitting:" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	
	FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
	EUOperation* operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+openFitWithURL" name:NSLocalizedString(@"Loading Ship Fit", nil)];
	__weak EUOperation* weakOperation = operation;
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	
	[operation addExecutionBlock:^{
		character = new eufe::Character(fittingViewController.fittingEngine);
		
		EVEAccount* currentAccount = [EVEAccount currentAccount];
		weakOperation.progress = 0.3;
		if (currentAccount.characterSheet) {
			FitCharacter* fitCharacter = [FitCharacter fitCharacterWithAccount:currentAccount];
			character->setCharacterName([fitCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[fitCharacter skillsMap]);
		}
		else
			character->setCharacterName([NSLocalizedString(@"All Skills 0", nil) UTF8String]);
		weakOperation.progress = 0.6;
		fit = [[ShipFit alloc] initWithDNA:dna character:character];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled]) {
			if (fit) {
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.controller dismissViewControllerAnimated:NO completion:nil];
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					UINavigationController* navigationController = [[(UISplitViewController*) self.controller viewControllers] objectAtIndex:1];
					[navigationController pushViewController:fittingViewController animated:YES];
				}
				else
					[(UINavigationController*)self.controller pushViewController:fittingViewController animated:YES];
			}
			else {
				if (character)
					delete character;
			}
		}
		else {
			if (character)
				delete character;
		}
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) configureCloudWithCompletionHandler:(void(^)()) completionHandler {
/*	NSNumber* useCloud = [[NSUserDefaults standardUserDefaults] valueForKey:SettingsUseCloud];
	id currentCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
	if (useCloud == nil && currentCloudToken) {
		[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Choose Storage Option", nil)
								 message:NSLocalizedString(@"Should documents be stored in iCloud and available on all your devices? Initializing Cloud Storage can take a few minutes.", nil)
					   cancelButtonTitle:NSLocalizedString(@"Local Only", nil)
					   otherButtonTitles:@[NSLocalizedString(@"iCloud", nil)]
						 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
							 [[NSUserDefaults standardUserDefaults] setBool:selectedButtonIndex != alertView.cancelButtonIndex
																	 forKey:SettingsUseCloud];
							 completionHandler();
						 } cancelBlock:nil] show];
	}
	else*/
		completionHandler();
}

- (void) setupAppearance {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
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
		[[UITableView appearance] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBar.png"] forBarMetrics:UIBarMetricsDefault];
		//[[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	}
	else {
		[[UITableView appearance] setSeparatorStyleAppearance:UITableViewCellSeparatorStyleNone];
//		[[UITableView appearance] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
//		[[UITableView appearance] setSeparatorColor:[UIColor colorWithNumber:AppearanceSeparatorColor]];
		//[[NSClassFromString(@"UISearchResultsTableView") appearance] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
		//[self.window setValue:[UIColor whiteColor] forKey:@"tintColor"];
//		[[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
		//[[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeFont: [UIFont systemFontOfSize:14]} forState:UIControlStateNormal];
		//[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 4) forBarMetrics:UIBarMetricsDefault];
		
		[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithNumber:AppearanceNavigationBarColor]];
		[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
		
//		[[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBarTintColor:nil];
//		[[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setTintColor:[UIColor blackColor]];
	}
	
	[[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
	[[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeTextShadowColor: [UIColor blackColor], UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)]}];
	[[UINavigationBar appearance] setTranslucentAppearance:NO];


	//[[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -2) forBarMetrics:UIBarMetricsDefault];
	//[[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:1 forBarMetrics:UIBarMetricsDefault];
	
	
	
	[[UISegmentedControl appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
											   forState:UIControlStateNormal
											 barMetrics:UIBarMetricsDefault];
	[[UISegmentedControl appearance] setBackgroundImage:[[UIImage imageNamed:@"buttonBackgroundBlack.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)]
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
//	[[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar.png"]];
//	[[UISearchBar appearance] setSearchFieldBackgroundImage:[[UIImage imageNamed:@"textFieldBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 17, 0, 17)] forState:UIControlStateNormal];
	[[UISearchBar appearance] setTextColor:[UIColor whiteColor]];
	[[UISearchBar appearance] setImage:[UIImage imageNamed:@"iconClear.png"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
	[[UISearchBar appearance] setImage:[UIImage imageNamed:@"iconClearSelected.png"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
	[[UISearchBar appearance] setImage:[UIImage imageNamed:@"iconSearch.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
	
	//[[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setBackgroundImage:[[UIImage imageNamed:@"textFieldBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 17, 0, 17)]];
	
	//[[UINavigationBar appearance] setTintColor:[UIColor colorWithNumber:@(0x1c1b20ff)]];
}

- (void) accountDidSelect:(NSNotification*) notification {
	EVEAccount* account = notification.object;
	if (account)
		[[NSUserDefaults standardUserDefaults] setInteger:account.character.characterID forKey:SettingsCurrentCharacterID];
	else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:SettingsCurrentCharacterID];
}

- (void) removeAds {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.adView removeFromSuperview];
		self.adView = nil;
	}
	else {
		if (self.adView) {
			UIView* contentView = [self.window.rootViewController valueForKey:@"navigationTransitionView"];
			contentView.frame = contentView.superview.bounds;
			[self.adView removeFromSuperview];
			self.adView = nil;
		}
	}
}

@end

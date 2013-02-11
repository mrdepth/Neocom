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
#import "EVERequestsCache.h"
#import "EUMailBox.h"
#import "EUActivityView.h"
#import "FittingViewController.h"
#import "CharacterEVE.h"
#import "ShipFit.h"
#import "EUStorage.h"
#import "EUMigrationManager.h"
#import "UIAlertView+Block.h"

@interface EVEUniverseAppDelegate() {
	BOOL launchingFinished;
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) updateNotifications;
- (void) addAPIKeyWithURL:(NSURL*) url;
- (void) openFitWithURL:(NSURL*) url;
- (void) configureCloudWithCompletionHandler:(void(^)()) completionHandler;

@end

@implementation EVEUniverseAppDelegate

@synthesize window;
@synthesize controller;
@synthesize loadingViewController;
@synthesize currentAccount;
@synthesize sharedQueue;
@synthesize sharedAccountStorage;

#pragma mark -
#pragma mark Application lifecycle


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
	
	updateNotificationsQueue = [[NSOperationQueue alloc] init];

	NSURL *cacheFileURL = [NSURL fileURLWithPath:[EVERequestsCache cacheFileName]];
	NSDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfURL:cacheFileURL];
	NSArray *values = [cache allValues];
	if (values.count > 0 && [[values objectAtIndex:0] isKindOfClass:[NSDate class]]) {
		[[NSFileManager defaultManager] removeItemAtURL:cacheFileURL  error:nil];
		[[EVERequestsCache sharedRequestsCache] clear];
	}
	
	UILocalNotification *notification = [launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	if (notification) {
		[[NSUserDefaults standardUserDefaults] setObject:notification.userInfo forKey:SettingsCurrentAccount];
	}
	
	[window addSubview:controller.view];
	[window makeKeyAndVisible];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:[[Globals documentsDirectory] stringByAppendingPathComponent:@"disableActivityIndicator"]]) {
		EUActivityView* activityView = [[[EUActivityView alloc] initWithFrame:self.window.rootViewController.view.bounds] autorelease];
		[self.window addSubview:activityView];
	}
	
	
	loadingViewController.view.alpha = 0;
	[window addSubview:loadingViewController.view];
	loadingViewController.view.center = CGPointMake(self.window.frame.size.width / 2, self.window.frame.size.height / 2);
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:SettingsNoAds]) {
		CGSize gadSize = CGSizeMake(320, 50);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UISplitViewController* splitViewController = (UISplitViewController*) self.controller;
			CGRect frame = [[[splitViewController.viewControllers objectAtIndex:0] view] frame];
			adView = [[GADBannerView alloc] initWithFrame:CGRectMake(0, frame.size.height - gadSize.height, gadSize.width, gadSize.height)];
			adView.rootViewController = self.controller;
			adView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
			[[[splitViewController.viewControllers objectAtIndex:0] view] addSubview:adView];
		}
		else {
			CGRect frame = [[UIScreen mainScreen] bounds];
			frame.origin.y = frame.size.height - gadSize.height;
			frame.size.height = gadSize.height;
			adView = [[GADBannerView alloc] initWithFrame:frame];
			adView.rootViewController = self.controller;
			[controller.view addSubview:adView];
		}
		
		adView.adUnitID = @"a14d501062a8c09";
		GADRequest *request = [GADRequest request];
		[adView loadRequest:request];
		
	}
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	
	[self configureCloudWithCompletionHandler:^{
		self.window.userInteractionEnabled = NO;
		__block EUOperation* operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+migrate" name:NSLocalizedString(@"Initializing storage.", nil)];
		[operation addExecutionBlock:^{
			@autoreleasepool {
				EUMigrationManager* migrationManager = [[EUMigrationManager alloc] init];
				[migrationManager migrateIfNeeded];
				[migrationManager release];
			}
		}];
		[operation setCompletionBlockInCurrentThread:^{
			launchingFinished = YES;
			
			EVEAccount *account = [EVEAccount accountWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SettingsCurrentAccount]];
			self.currentAccount = account;
			[self updateNotifications];
			self.window.userInteractionEnabled = YES;
		}];
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	if (launchingFinished) {
		EVEAccount *account = [EVEAccount accountWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SettingsCurrentAccount]];
		self.currentAccount = account;
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
		[alert release];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:notification.userInfo forKey:SettingsCurrentAccount];
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
	if (value != currentAccount) {
		[value retain];
		[currentAccount release];
		currentAccount = value;
	}
	if (currentAccount) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSelectAccount object:currentAccount];
	}
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSelectAccount object:currentAccount];
	if (!currentAccount)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:SettingsCurrentAccount];
	else
		[[NSUserDefaults standardUserDefaults] setObject:[currentAccount dictionary] forKey:SettingsCurrentAccount];
	
	if (currentAccount && ((currentAccount.charAccessMask & 49152) == 49152)) { //49152 = NotificationTexts | Notifications
		NSMutableArray* wars = [NSMutableArray array];
		
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+CheckMail" name:NSLocalizedString(@"Checking War Declarations", nil)];
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			EUMailBox* mailBox = [currentAccount mailBox];
			NSMutableSet* ids = [NSMutableSet set];
			float n = mailBox.notifications.count + 1;
			float i = 0;
			for (EUNotification* notification in  mailBox.notifications) {
				operation.progress = i++ / n;
				if (!notification.read && (notification.header.typeID == 5 || notification.header.typeID == 27)) {
					NSString* declaredByID = [notification.details.properties valueForKey:@"declaredByID"];
					NSInteger iDeclaredByID = [declaredByID integerValue];
					if (declaredByID && currentAccount.characterSheet.corporationID != iDeclaredByID && currentAccount.characterSheet.allianceID != iDeclaredByID)
						[ids addObject:declaredByID];
				}
			}
			if (ids.count > 0) {
				EVECharacterName* charNames = [EVECharacterName characterNameWithIDs:[ids allObjects] error:nil];
				
				for (NSString* war in [charNames.characters allValues]) {
					[wars addObject:war];
				}
			}
			operation.progress = 1;
			[mailBox save];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
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
				[alertView release];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

- (BOOL) isInAppStatus {
	@synchronized(self) {
		return inAppStatus;
	}
}

- (void) setInAppStatus:(BOOL)value {
	@synchronized(self) {
		inAppStatus = value;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0.5];
		loadingViewController.view.alpha = inAppStatus ? 1 : 0;
		[UIView commitAnimations];
	}
}

- (EUOperationQueue*) sharedQueue {
	if (!sharedQueue) {
		sharedQueue = [[EUOperationQueue alloc] init];
	}
	return sharedQueue;
}

- (EVEAccountStorage*) sharedAccountStorage {
	@synchronized(self) {
		if (!sharedAccountStorage) {
			sharedAccountStorage = [[EVEAccountStorage alloc] init];
		}
		return sharedAccountStorage;
	}
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


- (void)dealloc {
    [window release];
	[controller release];
	[loadingViewController release];
	[currentAccount release];
	[adView release];
	[sharedQueue release];
	[sharedAccountStorage release];
	[updateNotificationsQueue release];
    [super dealloc];
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


#pragma mark - Private

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNoAds];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[adView removeFromSuperview];
	[adView release];
	adView = nil;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Thanks for the donation", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
	[alertView autorelease];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNoAds];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	[adView removeFromSuperview];
	[adView release];
	adView = nil;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Your donation status has been restored", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
	[alertView show];
	[alertView autorelease];
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

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+updateNotifications" name:NSLocalizedString(@"Updating Notifications", nil)];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		EVEAccountStorage *storage = [EVEAccountStorage sharedAccountStorage];
		float n = storage.characters.count;
		float i = 0;
		for (EVEAccountStorageCharacter *item in [storage.characters allValues]) {
			operation.progress = i++ / n;
			if (item.enabled) {
				EVEAccountStorageAPIKey *apiKey = item.anyCharAPIKey;
				if (apiKey) {
					NSError *error = nil;
					EVESkillQueue *skillQueue = [EVESkillQueue skillQueueWithKeyID:apiKey.keyID vCode:apiKey.vCode characterID:item.characterID error:&error];
					if (!error && skillQueue.skillQueue.count > 0) {
						NSDate *endTime = [[skillQueue.skillQueue lastObject] endTime];
						if (endTime) {
							endTime = [skillQueue localTimeWithServerTime:endTime];
							NSTimeInterval dif = [endTime timeIntervalSinceNow];
							if (dif > 3600 * 24) {
								UILocalNotification *notification = [[UILocalNotification alloc] init];
								notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ has less than 24 hours training left.", nil), item.characterName];
								notification.fireDate = [endTime dateByAddingTimeInterval:- 3600 * 24];
								EVEAccount *account = [EVEAccount accountWithCharacter:item];
								notification.userInfo = [account dictionary];
								[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(scheduleLocalNotification:) withObject:notification waitUntilDone:NO];
								[notification release];
							}
						}
					}
				}
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (updateNotificationsOperation == operation)
			updateNotificationsOperation = nil;
	}];
	
	if (updateNotificationsOperation)
		[operation addDependency:updateNotificationsOperation];
	updateNotificationsOperation = operation;
	[updateNotificationsQueue addOperation:operation];
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
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"EVEUniverseAppDelegate+AddAPIKey" name:NSLocalizedString(@"Adding API Key", nil)];
	__block NSError *error = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:[[properties valueForKey:@"keyid"] integerValue] vCode:[properties valueForKey:@"vcode"] error:&error];
		[error retain];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (error) {
			[[UIAlertView alertViewWithError:error] show];
		}
		else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"API Key added", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
			[alertView show];
			[alertView release];
			[[NSNotificationCenter defaultCenter] postNotificationName:NotificationAccountStoargeDidChange object:nil];
		}
		[error release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) openFitWithURL:(NSURL*) url {
	NSMutableString* dna = [NSMutableString stringWithString:[url absoluteString]];
	[dna replaceOccurrencesOfString:@"fitting://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	[dna replaceOccurrencesOfString:@"fitting:" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dna.length)];
	
	FittingViewController *fittingViewController = [[FittingViewController alloc] initWithNibName:@"FittingViewController" bundle:nil];
	__block EUOperation* operation = [EUOperation operationWithIdentifier:@"AssetContentsViewController+OpenFit" name:NSLocalizedString(@"Loading Ship Fit", nil)];
	__block ShipFit* fit = nil;
	__block eufe::Character* character = NULL;
	
	[operation addExecutionBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		character = new eufe::Character(fittingViewController.fittingEngine);
		
		EVEAccount* theCurrentAccount = [EVEAccount currentAccount];
		operation.progress = 0.3;
		if (theCurrentAccount && theCurrentAccount.charKeyID && theCurrentAccount.charVCode && theCurrentAccount.characterID) {
			CharacterEVE* eveCharacter = [CharacterEVE characterWithCharacterID:theCurrentAccount.characterID keyID:theCurrentAccount.charKeyID vCode:theCurrentAccount.charVCode name:theCurrentAccount.characterName];
			character->setCharacterName([eveCharacter.name cStringUsingEncoding:NSUTF8StringEncoding]);
			character->setSkillLevels(*[eveCharacter skillsMap]);
		}
		else
			character->setCharacterName("All Skills 0");
		operation.progress = 0.6;
		fit = [[ShipFit alloc] initWithDNA:dna character:character];
		operation.progress = 1.0;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![operation isCancelled]) {
			if (fit) {
				fittingViewController.fittingEngine->getGang()->addPilot(character);
				fittingViewController.fit = fit;
				[fittingViewController.fits addObject:fit];
				[self.controller dismissModalViewControllerAnimated:NO];
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
		[fittingViewController release];
		[fit release];
	}];
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) configureCloudWithCompletionHandler:(void(^)()) completionHandler {
	NSNumber* useCloud = [[NSUserDefaults standardUserDefaults] valueForKey:SettingsUseCloud];
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
	else
		completionHandler();
}

@end

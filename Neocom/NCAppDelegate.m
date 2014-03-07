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

@interface NCAppDelegate()
@property (nonatomic, strong) NCTaskManager* taskManager;
- (void) addAPIKeyWithURL:(NSURL*) url;
- (void) openFitWithURL:(NSURL*) url;
@end

@implementation NCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSData* data = [NSData dataWithContentsOfFile:@"/Users/shimanski/tmp/dbInit.sql"];
	data = [data uncompressedData];
	NSString* s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	if (![[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsUDID])
		[[NSUserDefaults standardUserDefaults] setValue:[NSString uuidString] forKey:NCSettingsUDID];

	self.taskManager = [NCTaskManager new];
	
/*	EVECachedURLRequest* request = [[EVECachedURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://request.urih.com/"]
																cachePolicy:NSURLRequestUseProtocolCachePolicy
																	  error:nil
															progressHandler:nil];*/
	
	
//	NCSkillPlan* skillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:[[NCStorage sharedStorage] managedObjectContext]]
//								  insertIntoManagedObjectContext:nil];
//	skillPlan = nil;
	NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
	NSError* error = nil;
	//[accountsManager addAPIKeyWithKeyID:521 vCode:@"m2jHirH1Zvw4LFXiEhuQWsofkpV1th970oz2XGLYZCorWlO4mRqvwHalS77nKYC1" error:&error];
	//[accountsManager addAPIKeyWithKeyID:519 vCode:@"IiEPrrQTAdQtvWA2Aj805d0XBMtOyWBCc0zE57SGuqinJLKGTNrlinxc6v407Vmf" error:&error];
	//[accountsManager addAPIKeyWithKeyID:661 vCode:@"fNYa9itvXjnU8IRRe8R6w3Pzls1l8JXK3b3rxTjHUkTSWasXMZ08ytWHE0HbdWed" error:&error];
	
	NCAccount* account = nil;
	NCStorage* storage = [NCStorage sharedStorage];

	if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
		UILocalNotification* notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
		NSString* urlString = notification.userInfo[NCSettingsCurrentAccountKey];
		NSURL* url = [NSURL URLWithString:urlString];
		if (url)
			account = (NCAccount*) [storage.managedObjectContext existingObjectWithID:[storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url] error:nil];
	}
	
	if (!account) {
		NSURL* url = [[NSUserDefaults standardUserDefaults] URLForKey:NCSettingsCurrentAccountKey];
		if (url)
			account = (NCAccount*) [storage.managedObjectContext existingObjectWithID:[storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url] error:nil];
	}
	if (account)
		[NCAccount setCurrentAccount:account];
	
	if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
		[application setMinimumBackgroundFetchInterval:60 * 60 * 4];
		
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
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
											 NSInteger keyID = [properties[@"keyid"] integerValue];
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
}

@end

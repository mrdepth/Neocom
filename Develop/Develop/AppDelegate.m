//
//  AppDelegate.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "AppDelegate.h"
#import "NCCache.h"
#import "NCDataManager.h"
#import "NCDatabase.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	dispatch_group_t dispatchGroup = dispatch_group_create();
	
	dispatch_group_enter(dispatchGroup);
	NCCache* cache = [NCCache new];
	[cache loadWithCompletionHandler:^(NSError *error) {
		NCCache.sharedCache = cache;
		dispatch_group_leave(dispatchGroup);
	}];

//	dispatch_group_enter(dispatchGroup);
//	NCDatabase* database = [NCDatabase new];
//	[database loadWithCompletionHandler:^(NSError *error) {
//		NCDatabase.sharedDatabase = database;
//		dispatch_group_leave(dispatchGroup);
//	}];

	dispatch_group_enter(dispatchGroup);
	NCStorage* storage = [NCStorage localStorage];
	[storage loadWithCompletionHandler:^(NSError *error) {
		NCStorage.sharedStorage = storage;
		dispatch_group_leave(dispatchGroup);
	}];

	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^ {
		
		/*[[NCDataManager new] addAPIKeyWithKeyID:519 vCode:@"IiEPrrQTAdQtvWA2Aj805d0XBMtOyWBCc0zE57SGuqinJLKGTNrlinxc6v407Vmf" completionBlock:^(NSArray<NSManagedObjectID *> *accounts, NSError *error) {
			id result = [NCStorage.sharedStorage.viewContext objectWithID:accounts[0]];
			NSLog(@"%@", result);
		}];*/
		NCAccount* account = [[NCStorage.sharedStorage.viewContext executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"Account"] error:nil] lastObject];
		NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
		[progress addObserver:self forKeyPath:@"fractionCompleted" options:0 context:nil];
		[progress becomeCurrentWithPendingUnitCount:1];
		[[NCDataManager new] characterSheetForAccount:account cachePolicy:NSURLRequestReloadIgnoringCacheData completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			NSLog(@"%@", [NCCache.sharedCache.viewContext objectWithID:cacheRecordID]);
			NSLog(@"%@", progress);
		}];
		[progress resignCurrent];
	});
	
	return YES;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	NSLog(@"%@", object);
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

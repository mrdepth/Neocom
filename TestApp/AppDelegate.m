//
//  AppDelegate.m
//  TestApp
//
//  Created by Артем Шиманский on 14.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "AppDelegate.h"
#import "NCStorage.h"
#import "NCAccountsManager.h"
#import "NCCache.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[NCStorage setSharedStorage:[[NCStorage alloc] initLocalStorage]];
	
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.fetchLimit = 1;
	NSManagedObjectContext* db = [[NCDatabase sharedDatabase] managedObjectContext];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		__block NSManagedObjectContext* context = [[NCStorage sharedStorage] createManagedObjectContext];
		[[[NCDatabase sharedDatabase] managedObjectContext] performBlockAndWait:^{
			[context performBlockAndWait:^{
				NCDBInvType* type = [NCDBInvType invTypeWithTypeID:645];
				[type category];
				NSLog(@"%@", type);
				context = nil;
				//NSLog(@"a %@", [[db executeFetchRequest:request error:nil] valueForKey:@"typeID"]);
			}];
			NSLog(@"b %@", [[db executeFetchRequest:request error:nil] valueForKey:@"typeID"]);
		}];
	});

	[[[NCDatabase sharedDatabase] managedObjectContext] performBlock:^{
	}];
/*	[NCStorage setSharedStorage:[[NCStorage alloc] initLocalStorage]];
	[NCAccountsManager setSharedManager:[[NCAccountsManager alloc] initWithStorage:[NCStorage sharedStorage]]];
	
	[[NCAccountsManager sharedManager] loadAccountsWithCompletionBlock:^(NSArray *accounts) {
		NCAccount* account = [accounts lastObject];
		[account.managedObjectContext performBlock:^{
			[account.activeSkillPlan loadTrainingQueueWithCompletionBlock:^(NCTrainingQueue *trainingQueue) {
				[[[NCDatabase sharedDatabase] managedObjectContext] performBlock:^{
					[trainingQueue addRequiredSkillsForType:[NCDBInvType invTypeWithTypeID:671]];
					[account.managedObjectContext performBlock:^{
						[account.activeSkillPlan save];
					}];
				}];
			}];
		}];
		[account reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy completionBlock:^(NSError *error) {
		} progressBlock:nil];
	}];*/
	// Override point for customization after application launch.
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

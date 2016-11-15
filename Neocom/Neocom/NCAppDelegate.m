//
//  NCAppDelegate.m
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAppDelegate.h"
#import "NCCache.h"
#import "NCStorage.h"
#import "NCDatabase.h"

@interface NCAppDelegate()<UISplitViewControllerDelegate>

@end

@implementation NCAppDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(nullable id)sender {
	return NO;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(nullable id)sender {
	//UINavigationController* nav = [splitViewController.viewControllers[0] childViewControllers][0];
	//[nav pushViewController:vc animated:YES];
	return NO;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSDateIntervalFormatter* formatter = [NSDateIntervalFormatter new];
	formatter.dateStyle = NSDateIntervalFormatterNoStyle;
	formatter.timeStyle = NSDateIntervalFormatterFullStyle;
	NSString* s = [formatter stringFromDate:[NSDate date] toDate:[NSDate dateWithTimeIntervalSinceNow:120]];
	NSLog(@"%@", s);
	
	dispatch_group_t dispatchGroup = dispatch_group_create();
	
	dispatch_group_enter(dispatchGroup);
	NCCache* cache = [NCCache new];
	[cache loadWithCompletionHandler:^(NSError *error) {
		NCCache.sharedCache = cache;
		dispatch_group_leave(dispatchGroup);
	}];
	
	dispatch_group_enter(dispatchGroup);
	NCStorage* storage = [NCStorage localStorage];
	[storage loadWithCompletionHandler:^(NSError *error) {
		NCStorage.sharedStorage = storage;
		dispatch_group_leave(dispatchGroup);
	}];
	
	dispatch_group_enter(dispatchGroup);
	NCDatabase* database = [NCDatabase new];
	[database loadWithCompletionHandler:^(NSError *error) {
		NCDatabase.sharedDatabase = database;
		dispatch_group_leave(dispatchGroup);
	}];
	
	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
		
	});
	
	UISplitViewController* splitController = (UISplitViewController*) self.window.rootViewController;
	splitController.delegate = self;
	
	NSArray* sizes = @[
					   UIContentSizeCategoryUnspecified,
					   UIContentSizeCategoryExtraSmall,
					   UIContentSizeCategorySmall,
					   UIContentSizeCategoryMedium,
					   UIContentSizeCategoryLarge,
					   UIContentSizeCategoryExtraLarge,
					   UIContentSizeCategoryExtraExtraLarge,
					   UIContentSizeCategoryExtraExtraExtraLarge,
					   
					   // Accessibility sizes
					   UIContentSizeCategoryAccessibilityMedium,
					   UIContentSizeCategoryAccessibilityLarge,
					   UIContentSizeCategoryAccessibilityExtraLarge,
					   UIContentSizeCategoryAccessibilityExtraExtraLarge,
					   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge];
	
	NSArray* styles = @[
						UIFontTextStyleTitle1,
						UIFontTextStyleTitle2,
						UIFontTextStyleTitle3,
						UIFontTextStyleHeadline,
						UIFontTextStyleSubheadline,
						UIFontTextStyleBody,
						UIFontTextStyleCallout,
						UIFontTextStyleFootnote,
						UIFontTextStyleCaption1,
						UIFontTextStyleCaption2];
	
	for (NSString* style in styles) {
		UIFont* normal = [UIFont preferredFontForTextStyle:style compatibleWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryMedium]];
		NSLog(@"--- %@ %f", style, normal.pointSize);
		for (NSString* size in sizes) {
			UIFont* font = [UIFont preferredFontForTextStyle:style compatibleWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:size]];
			NSLog(@"%@ %f %f", size, font.pointSize, font.pointSize - normal.pointSize);
		}
	}
	
	return YES;
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

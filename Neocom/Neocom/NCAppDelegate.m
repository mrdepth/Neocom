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
#import "NCNavigationController.h"
#import "NCBannerNavigationController.h"
#import "NCBackgroundView.h"
#import "UIColor+CS.h"
#import "UIColor+Dark.h"
#import "NCTableView.h"
#import "NCTableViewCell.h"
#import "NSURL+NC.h"
#import "NCAddAPIKeyViewController.h"
#import "UIViewController+NC.h"
#import "NCSheetPresentationController.h"
#import "unitily.h"
#import "UIImage+NC.h"
@import ImageIO;

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
	[UIColor setCurrentScheme:CSSchemeDark];
	[self loadDatabases];
	[self setupAppearance];
	
	UISplitViewController* splitController = (UISplitViewController*) self.window.rootViewController;
	splitController.delegate = self;
	
	/*NSArray* sizes = @[
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
	}*/
	
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if ([url.scheme isEqualToString:@"eve"])
		return [self handleOpenURLSchemeEVE:url];
	else
		return NO;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [self application:app openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

#pragma mark - Private

- (void) loadDatabases {
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
		NSString* uri = [[NSUserDefaults standardUserDefaults] valueForKey:NCCurrentAccountKey];
		if (uri) {
			NSManagedObjectID* objectID = [storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:uri]];
			if (objectID) {
				NCAccount* account = [storage.viewContext existingObjectWithID:objectID error:nil];
				if (account)
					NCAccount.currentAccount = account;
			}
		}
	});
}

- (void) setupAppearance {
	UINavigationBar* navigationBar = [UINavigationBar appearanceWhenContainedIn:[NCNavigationController class], nil];
	//[navigationBar setBackgroundImage:[UIImage imageNamed:@"clear"] forBarMetrics:UIBarMetricsDefault];
	[navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor backgroundColor]] forBarMetrics:UIBarMetricsDefault];
	//[navigationBar setShadowImage:[UIImage imageNamed:@"clear"]];
	[navigationBar setShadowImage:[UIImage imageWithColor:[UIColor backgroundColor]]];
	[navigationBar setBarTintColor:[UIColor backgroundColor]];
	
	NCTableView*  tableView = [NCTableView appearance];
	[tableView setBackgroundColor:[UIColor backgroundColor]];
	[tableView setSeparatorColor:[UIColor separatorColor]];
	
	[[NCTableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
	[[NCBackgroundView appearance] setBackgroundColor:[UIColor backgroundColor]];
	
	UISearchBar* searchBar = [UISearchBar appearanceWhenContainedIn:[NCTableView class], nil];
	searchBar.barTintColor = [UIColor backgroundColor];
	searchBar.tintColor = [UIColor whiteColor];
	[searchBar setSearchFieldBackgroundImage:[UIImage searchFieldBackgroundImageWithColor:[UIColor separatorColor]] forState:UIControlStateNormal];
	searchBar.backgroundImage = [UIImage imageWithColor:[UIColor backgroundColor]];
}

- (BOOL) handleOpenURLSchemeEVE:(NSURL*) url {
	NSDictionary* parameters = url.parameters;
	NSInteger keyID = [parameters[@"keyID"] integerValue];
	NSString* vCode = parameters[@"vCode"];
	if (keyID && vCode.length > 0) {
		UIViewController* topmostController = [self.window.rootViewController topmostViewController];
		if ([topmostController isKindOfClass:[UINavigationController class]]) {
			UIViewController* topViewController = [(UINavigationController*) topmostController topViewController];
			if ([topViewController isKindOfClass:[NCAddAPIKeyViewController class]]) {
				NCAddAPIKeyViewController* addAPIKeyViewController = (NCAddAPIKeyViewController*)topViewController;
				[addAPIKeyViewController setKeyID:keyID vCode:vCode];
				return YES;
			}
		}
		UINavigationController* navigationController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"NCAddAPIKeyNavigationViewController"];
		NCAddAPIKeyViewController* addAPIKeyViewController = (NCAddAPIKeyViewController*) navigationController.topViewController;
		NCSheetPresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
		presentationController = [[NCSheetPresentationController alloc] initWithPresentedViewController:navigationController presentingViewController:topmostController];
		navigationController.transitioningDelegate = presentationController;

		[topmostController presentViewController:navigationController animated:YES completion:^{
			[addAPIKeyViewController setKeyID:keyID vCode:vCode];
		}];

		return YES;
	}
	else
		return NO;
}


@end

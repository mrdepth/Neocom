//
//  MainMenuViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenuViewController.h"
#import "ItemsDBViewController.h"
#import "MarketGroupsViewController.h"
#import "SelectCharacterBarButtonItem.h"
#import "SkillsViewController.h"
#import "EVEAccount.h"
#import "EVEOnlineAPI.h"
#import "CharacterInfoViewController.h"
#import "RSSFeedsViewController.h"
#import "GroupedCell.h"
#import "Globals.h"
#import "AboutViewController.h"
#import "WalletTransactionsViewController.h"
#import "MarketOrdersViewController.h"
#import "IndustryJobsViewController.h"
#import "SplashScreenViewController.h"
#import "UIColor+NSNumber.h"
#import "AccessMaskViewController.h"
#import "UIViewController+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "appearance.h"
#import "UIActionSheet+Block.h"

@interface MainMenuViewController()
@property (nonatomic, strong) UIPopoverController* masterPopover;
@property (nonatomic, assign) NSInteger numberOfUnreadMessages;
@property (nonatomic, strong) NSString* skillsDetails;
@property (nonatomic, strong) NSString* mailsDetails;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) EVEServerStatus* serverStatus;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) UIActionSheet* actionSheet;

- (void) accountDidSelect:(NSNotification*) notification;
- (void) didReadMail:(NSNotification*) notification;
- (void) loadMail;
- (void) onTimer:(NSTimer*) timer;
- (void) checkServerStatus;

@end


@implementation MainMenuViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Home", nil);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self.splitViewController]];
	}
	else {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	}
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.menuItems = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]]];
	[self.characterInfoView addSubview:self.characterInfoViewController.view];
	self.characterInfoViewController.view.frame = self.characterInfoView.bounds;
	self.characterInfoViewController.account = [EVEAccount currentAccount];

	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidSelect:) name:EVEAccountDidSelectNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReadMail:) name:NotificationReadMail object:nil];
	self.numberOfUnreadMessages = 0;
	[self loadMail];
	
	double delayInSeconds = 0.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[EVECachedURLRequest isOfflineMode] ? NSLocalizedString(@"Offline", nil) : NSLocalizedString(@"Online", nil)
																				 style:UIBarButtonItemStyleBordered
																				target:self
																				action:@selector(onChangeOnlineMode:)];
	});
	
//	self.onlineModeSegmentedControl.selectedSegmentIndex = [EVECachedURLRequest isOfflineMode] ? 1 : 0;
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	self.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	[self.dateFormatter setDateFormat:@"HH:mm:ss"];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.serverTimeLabel.text = nil;
	if (self.serverStatus.serverOpen) {
		self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
		[self onTimer:self.timer];
	}
	else if (!self.serverStatus)
		[self checkServerStatus];
}

- (void) viewWillDisappear:(BOOL)animated {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.timer invalidate];
	self.timer = nil;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self.characterInfoViewController];
}

- (IBAction)onFacebook:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com/groups/Neocom/"]];
}

- (IBAction)onChangeOnlineMode:(id)sender {
	[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:NO];
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:@[NSLocalizedString(@"Online mode", nil), NSLocalizedString(@"Offline mode", nil)]
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   BOOL offline = selectedButtonIndex == 1;
												   [EVECachedURLRequest setOfflineMode:offline];
												   [[NSUserDefaults standardUserDefaults] setBool:offline forKey:SettingsOfflineMode];
												   [[NSUserDefaults standardUserDefaults] synchronize];
												   
												   self.navigationItem.leftBarButtonItem.title = offline ? NSLocalizedString(@"Offline", nil) : NSLocalizedString(@"Online", nil);
											   }
											   self.actionSheet = nil;
										   }
											   cancelBlock:^{
												   self.actionSheet = nil;
											   }];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
//	[EVECachedURLRequest setOfflineMode:self.onlineModeSegmentedControl.selectedSegmentIndex == 1];
//	[[NSUserDefaults standardUserDefaults] setBool:self.onlineModeSegmentedControl.selectedSegmentIndex == 1 forKey:SettingsOfflineMode];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return self.menuItems.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.menuItems[section] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Cell";
	NSDictionary *item = self.menuItems[indexPath.section][indexPath.row];

	EVEAccount *account = [EVEAccount currentAccount];
	NSInteger charAccessMask = [[item valueForKey:@"charAccessMask"] integerValue];
	NSInteger corpAccessMask = [[item valueForKey:@"corpAccessMask"] integerValue];
	
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		//cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	NSString *className = [item valueForKey:@"className"];

	if (self.numberOfUnreadMessages > 0 && [className isEqualToString:@"MessagesViewController"]) {
		cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString([item valueForKey:@"title"], nil), self.numberOfUnreadMessages];
	}
	else {
		cell.textLabel.text = NSLocalizedString([item valueForKey:@"title"], nil);
	}
	
	if ((account.charAPIKey.apiKeyInfo.key.accessMask & charAccessMask) != charAccessMask &&
		(account.corpAPIKey.apiKeyInfo.key.accessMask & corpAccessMask) != corpAccessMask) {
		if (corpAccessMask > 0 && charAccessMask < 0 && !account.corpAPIKey)
			cell.detailTextLabel.text = NSLocalizedString(@"Requires a corp API key", nil);
		else if (charAccessMask > 0 && corpAccessMask > 0 && !account.charAPIKey && !account.corpAPIKey)
			cell.detailTextLabel.text = NSLocalizedString(@"Requires an API key", nil);
		else if (charAccessMask > 0 && corpAccessMask < 0 && !account.corpAPIKey)
			cell.detailTextLabel.text = NSLocalizedString(@"Requires a char API key", nil);
		else {
			if (charAccessMask > 0)
				cell.detailTextLabel.text = NSLocalizedString(@"Invalid char access mask", nil);
			else
				cell.detailTextLabel.text = NSLocalizedString(@"Invalid corp access mask", nil);
		}
		cell.textLabel.textColor = [UIColor lightTextColor];
	}
	else {
		cell.textLabel.textColor = [UIColor whiteColor];
		NSString* detailsKeyPath = item[@"detailsKeyPath"];
		cell.detailTextLabel.text = detailsKeyPath ? [self valueForKey:detailsKeyPath] : nil;
	}

	

	//cell.detailTextLabel.text = @"Details";
	cell.imageView.image = [UIImage imageNamed:[item valueForKey:@"image"]];
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *item = self.menuItems[indexPath.section][indexPath.row];

	EVEAccount *account = [EVEAccount currentAccount];
	NSInteger charAccessMask = [[item valueForKey:@"charAccessMask"] integerValue];
	NSInteger corpAccessMask = [[item valueForKey:@"corpAccessMask"] integerValue];
	
	if ((account.charAPIKey.apiKeyInfo.key.accessMask & charAccessMask) != charAccessMask &&
		(account.corpAPIKey.apiKeyInfo.key.accessMask & corpAccessMask) != corpAccessMask) {
		AccessMaskViewController* controller = [[AccessMaskViewController alloc] initWithNibName:@"AccessMaskViewController" bundle:nil];
		if (corpAccessMask > 0 && charAccessMask < 0) {
			controller.accessMask = account.corpAPIKey.apiKeyInfo.key.accessMask;
			controller.apiKeyType = EVEAPIKeyTypeCorporation;
			controller.requiredAccessMask = corpAccessMask;
		}
		else {
			controller.accessMask = account.charAPIKey.apiKeyInfo.key.accessMask;
			controller.apiKeyType = EVEAPIKeyTypeCharacter;
			controller.requiredAccessMask = charAccessMask;
		}
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
			[self presentViewControllerInPopover:navigationController
										fromRect:[tableView rectForRowAtIndexPath:indexPath]
										  inView:tableView
						permittedArrowDirections:UIPopoverArrowDirectionAny
										animated:YES];
		}
		else
			[self.navigationController pushViewController:controller animated:YES];
/*		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:controller action:@selector(dismiss)];
		[self presentViewController:navigationController animated:YES completion:nil];*/
		return;
	}

	NSString *className = [item valueForKey:@"className"];
	NSString *nibName = [item valueForKey:@"nibName"];
	Class class = NSClassFromString(className);
	if (!class)
		return;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if ([[item valueForKey:@"modal"] boolValue]) {
			UIViewController *controller = [[NSClassFromString(className) alloc] initWithNibName:nibName bundle:nil];
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			[navController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[controller.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self.splitViewController action:@selector(dismiss)]];
			[self.splitViewController presentViewController:navController animated:YES completion:nil];
		}
		else {
			NSArray *viewControllers = [self.splitViewController viewControllers];
			UINavigationController *navController = [viewControllers objectAtIndex:1];
			if ([[[[navController viewControllers] objectAtIndex:0] class] isEqual:class])
				[navController popToRootViewControllerAnimated:YES];
			else {
				UIViewController *controller = [[NSClassFromString(className) alloc] initWithNibName:nibName bundle:nil];
				navController = [[UINavigationController alloc] initWithRootViewController:controller];
				[navController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
				if (self.masterPopover) {
					UINavigationController* navigationController = [[self.splitViewController viewControllers] objectAtIndex:1];
					controller.navigationItem.leftBarButtonItem = [[[[navigationController viewControllers] objectAtIndex:0] navigationItem] leftBarButtonItem];
					[self.masterPopover dismissPopoverAnimated:YES];
				}
				[self.splitViewController setViewControllers:[NSArray arrayWithObjects:[viewControllers objectAtIndex:0], navController, nil]];
			}
		}
	}
	else {
		UIViewController *controller = [[NSClassFromString(className) alloc] initWithNibName:nibName bundle:nil];
		[self.navigationController pushViewController:controller animated:YES];
	}
	
	return;
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	CGRect frame = self.tableHeaderContentView.frame;
	if (scrollView.contentOffset.y < 0)
		frame.origin.y = scrollView.contentOffset.y;
	self.tableHeaderContentView.frame = frame;
}

#pragma mark ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
	barButtonItem.title = NSLocalizedString(@"Menu", nil);
	UINavigationController* navigationController = [[self.splitViewController viewControllers] objectAtIndex:1];
	[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:barButtonItem animated:YES];
	self.masterPopover = pc;
	navigationController = (UINavigationController*) aViewController;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	UINavigationController* navigationController = [[self.splitViewController viewControllers] objectAtIndex:1];
	[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:nil animated:YES];
	self.masterPopover = nil;
}

#pragma mark - Private

- (void) accountDidSelect:(NSNotification*) notification {
	EVEAccount* account = [EVEAccount currentAccount];
	self.characterInfoViewController.account = account;
	self.numberOfUnreadMessages = 0;
//	self.mailsDetails = [

	if (account.characterSheet) {
		NSInteger skillPoints = 0;
		for (EVECharacterSheetSkill* skill in account.characterSheet.skills)
			skillPoints += skill.skillpoints;
		self.skillsDetails = [NSString stringWithFormat:NSLocalizedString(@"%@ skillpoints (%d skills)", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:skillPoints], account.characterSheet.skills.count];
	}
	else
		self.skillsDetails = nil;
	
	self.mailsDetails = nil;
	[self.tableView reloadData];
	[self loadMail];
}

- (void) didReadMail:(NSNotification*) notification {
	[self loadMail];
}

- (void) loadMail {
	EVEAccount* currentAccount = [EVEAccount currentAccount];
	if (currentAccount) {
		__block NSInteger numberOfUnreadMessages;
		EUOperation *operation = [EUOperation operationWithIdentifier:@"MainMenuViewController+CheckMail" name:NSLocalizedString(@"Checking Mail", nil)];
		[operation addExecutionBlock:^(void) {
			@autoreleasepool {
				numberOfUnreadMessages = [[currentAccount mailBox] numberOfUnreadMessages];
			}
		}];
		
		__weak EUOperation* weakOperation = operation;
		[operation setCompletionBlockInMainThread:^(void) {
			if (numberOfUnreadMessages > 0)
				self.mailsDetails = [NSString stringWithFormat:NSLocalizedString(@"%d unread messages", nil), numberOfUnreadMessages];
			else
				self.mailsDetails = nil;
			if (![weakOperation isCancelled])
				[self.tableView reloadData];
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

- (void) checkServerStatus {
	__block EVEServerStatus* serverStatus = nil;
	EUOperation *operation = [EUOperation operationWithIdentifier:@"MainMenuViewController+checkServerStatus" name:NSLocalizedString(@"Updating Server Status", nil)];
	__block NSError* error = nil;
	[operation addExecutionBlock:^(void) {
		@autoreleasepool {
			serverStatus = [EVEServerStatus serverStatusWithError:&error progressHandler:nil];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.serverStatus = serverStatus;
		[self.timer invalidate];
		self.timer = nil;
		if (serverStatus.serverOpen) {
			self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
			self.onlineLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ player online", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:serverStatus.onlinePlayers]];
			[self onTimer:self.timer];
		}
		else if (error)
			self.onlineLabel.text = [error localizedDescription];
		else
			self.onlineLabel.text = NSLocalizedString(@"Server offline", nil);
		[self performSelector:@selector(checkServerStatus) withObject:nil afterDelay:30];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) onTimer:(NSTimer *)timer {
	if (self.serverStatus) {
		self.serverTimeLabel.text = [self.dateFormatter stringFromDate:[self.serverStatus serverTimeWithLocalTime:[NSDate date]]];
	}
	else {
		[self.timer invalidate];
		self.timer = nil;
	}
}

@end

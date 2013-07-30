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
#import "SBTableView.h"
#import "RSSFeedsViewController.h"
#import "MainMenuCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "AboutViewController.h"
#import "WalletTransactionsViewController.h"
#import "MarketOrdersViewController.h"
#import "IndustryJobsViewController.h"
#import "SplashScreenViewController.h"
#import "UIColor+NSNumber.h"
#import "AccessMaskViewController.h"
#import "UIViewController+Neocom.h"

@interface MainMenuViewController()
@property (nonatomic, strong) UIPopoverController* masterPopover;
@property (nonatomic, assign) NSInteger numberOfUnreadMessages;


- (void) accountDidSelect:(NSNotification*) notification;
- (IBAction) dismissModalViewController;
- (void) didReadMail:(NSNotification*) notification;
- (void) loadMail;

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
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.onlineModeSegmentedControl];
	self.title = NSLocalizedString(@"Home", nil);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self.splitViewController]];
		[self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundMenu~ipad.png"]]];
	}
	else {
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
		UIImage* image = [UIImage imageNamed:@"background.png"];
		image = [image resizableImageWithCapInsets:UIEdgeInsetsZero];
		//[self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:image]];
	}
	[self.tableView setBackgroundColor:[UIColor colorWithNumber:@(0x1f1e23ff)]];
	
	self.menuItems = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]]];
	[self.characterInfoView addSubview:self.characterInfoViewController.view];
	self.characterInfoViewController.view.frame = self.characterInfoView.bounds;
	self.characterInfoViewController.account = [EVEAccount currentAccount];

	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidSelect:) name:EVEAccountDidSelectNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReadMail:) name:NotificationReadMail object:nil];
	self.numberOfUnreadMessages = 0;
	[self loadMail];
	self.onlineModeSegmentedControl.selectedSegmentIndex = [EVECachedURLRequest isOfflineMode] ? 1 : 0;
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

- (void)viewDidUnload {
	[self setOnlineModeSegmentedControl:nil];
    [self setTableHeaderContentView:nil];
    [self setOnlineLabel:nil];
    [self setServerTimeLabel:nil];
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self.characterInfoViewController];
	self.characterInfoViewController = nil;
	self.menuItems = nil;
	self.characterInfoView = nil;
	self.masterPopover = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self.characterInfoViewController];
}

- (IBAction)onFacebook:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com/groups/Neocom/"]];
}

- (IBAction)onChangeOnlineMode:(id)sender {
	[EVECachedURLRequest setOfflineMode:self.onlineModeSegmentedControl.selectedSegmentIndex == 1];
	[[NSUserDefaults standardUserDefaults] setBool:self.onlineModeSegmentedControl.selectedSegmentIndex == 1 forKey:SettingsOfflineMode];
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
		cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
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
			cell.detailTextLabel.text = NSLocalizedString(@"Add corp API Key", nil);
		else if (charAccessMask > 0 && corpAccessMask > 0 && !account.charAPIKey && !account.corpAPIKey)
			cell.detailTextLabel.text = NSLocalizedString(@"Add char or corp API Key", nil);
		else if (charAccessMask > 0 && corpAccessMask < 0 && !account.corpAPIKey)
			cell.detailTextLabel.text = NSLocalizedString(@"Add char API Key", nil);
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
		cell.detailTextLabel.text = nil;
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
			[controller.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissModalViewController)]];
			[self.splitViewController presentModalViewController:navController animated:YES];
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
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	UINavigationController* navigationController = [[self.splitViewController viewControllers] objectAtIndex:1];
	[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:nil animated:YES];
	self.masterPopover = nil;
}

#pragma mark - Private

- (void) accountDidSelect:(NSNotification*) notification {
	self.characterInfoViewController.account = [EVEAccount currentAccount];
	self.numberOfUnreadMessages = 0;
	[self.tableView reloadData];
	[self loadMail];
}

- (IBAction) dismissModalViewController {
	[self.splitViewController dismissModalViewControllerAnimated:YES];
}

- (void) didReadMail:(NSNotification*) notification {
	[self loadMail];
}

- (void) loadMail {
	EVEAccount* currentAccount = [EVEAccount currentAccount];
	if (currentAccount) {
		EUOperation *operation = [EUOperation operationWithIdentifier:@"MainMenuViewController+CheckMail" name:NSLocalizedString(@"Checking Mail", nil)];
		[operation addExecutionBlock:^(void) {
			@autoreleasepool {
				self.numberOfUnreadMessages = [[currentAccount mailBox] numberOfUnreadMessages];
			}
		}];
		
		__weak EUOperation* weakOperation = operation;
		[operation setCompletionBlockInMainThread:^(void) {
			if (![weakOperation isCancelled])
				[self.tableView reloadData];
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

@end

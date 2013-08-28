//
//  MessagesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessagesViewController.h"
#import "EVEOnlineAPI.h"
#import "EVEDBAPI.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "SelectCharacterBarButtonItem.h"
#import "UIAlertView+Error.h"
#import "MessageCellView.h"
#import "EUMailBox.h"
#import "MessageViewController.h"
#import "appearance.h"

@interface MessagesViewController()

- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (void) reload;
@end

@implementation MessagesViewController


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	if (!self.title)
		self.title = NSLocalizedString(@"Mail", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)];
//		[self.navigationItem setRightBarButtonItem:];
		//self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)] autorelease];
		//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.toolbar];
	}
	else {
		self.tableView.tableHeaderView = self.searchBar;
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)];
	}
//	else
//		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:EVEAccountDidSelectNotification object:nil];
	//[self reloadMessages];
	if (self.messages) {
		self.messagesDataSource.messages = self.messages;;
		self.tableView.delegate = self.messagesDataSource;
		self.tableView.dataSource = self.messagesDataSource;
		//[self.messagesDataSource reload];
	}
	[self reload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.messages)
		[self.messageGroupsDataSource reload];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)markAsRead:(id)sender {
	if (self.messages) {
		for (EUMailMessage* message in self.messages)
			message.read = YES;
	}
	else {
		for (EUMailMessage* message in self.mailBox.inbox)
			message.read = YES;
	}
	[self.mailBox save];
	[self reload];
	[self.searchDisplayController.searchResultsTableView reloadData];
	[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:self.mailBox];
}

#pragma mark - MessageGroupsDataSourceDelegate

- (void) messageGroupsDataSource:(MessageGroupsDataSource*) dataSource didSelectGroup:(NSArray*) group withTitle:(NSString*) title {
	MessagesViewController* controller = [[MessagesViewController alloc] initWithNibName:@"MessagesViewController" bundle:nil];
	controller.messages = group;
	controller.title = title;
	[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - MessagesDataSourceDelegate

- (void) messageDataSource:(MessagesDataSource*) dataSource didSelectMessage:(EUMailMessage*) message {
	MessageViewController *controller = [[MessageViewController alloc] initWithNibName:@"MessageViewController" bundle:nil];
	controller.message = message;
	
	if (!message.read && message.text) {
		message.read = YES;
		[self.mailBox save];
		[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
		[self.searchDisplayController.searchResultsTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:self.mailBox];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[controller.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];
		[self presentViewController:navController animated:YES completion:nil];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self searchWithSearchString:searchString];
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	[self searchWithSearchString:controller.searchBar.text];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	tableView.backgroundView = nil;
	tableView.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Private

- (void) reload {
	if (self.messages) {
		[self.messagesDataSource reload];
	}
	else {
		__block EUMailBox* mailBoxTmp = nil;
		EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+reload" name:NSLocalizedString(@"Loading Messages", nil)];
		EVEAccount* account = [EVEAccount currentAccount];
		
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^(void) {
			mailBoxTmp = account.mailBox;
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				if (!mailBoxTmp.inbox) {
					NSError* error = mailBoxTmp ? mailBoxTmp.error : [NSError errorWithDomain:@"Neocom" code:0 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown error", nil) forKey:NSLocalizedDescriptionKey]];
					[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
					mailBoxTmp = nil;
				}
				self.mailBox = mailBoxTmp;
				self.messageGroupsDataSource.mailBox = self.mailBox;
				[self.messageGroupsDataSource reload];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];

	self.mailBox = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self reload];
	}
	else {
		if (!account)
			[self.navigationController popToRootViewControllerAnimated:YES];
		else if (self.messages)
			[self.navigationController popViewControllerAnimated:YES];
		else
			[self reload];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if ((self.messages.count == 0 && !self.mailBox) || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		if (self.messages) {
			for (EUMailMessage *message in self.messages) {
				if (([message.header.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.from rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.to rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[filteredValuesTmp addObject:message];
			}
		}
		else if (self.mailBox.inbox && self.mailBox.sent) {
			for (NSArray* array in @[self.mailBox.inbox, self.mailBox.sent]) {
				for (EUMailMessage *message in array) {
					if (([message.header.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
						([message.from rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
						([message.to rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
						[filteredValuesTmp addObject:message];
				}
			}
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.searchResultsDataSource.messages = filteredValuesTmp;
			[self.searchResultsDataSource reload];
			//self.filteredValues = filteredValuesTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
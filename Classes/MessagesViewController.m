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

@interface MessagesViewController(Private)
- (void) reloadMessages;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction)onClose:(id)sender;
@end

@implementation MessagesViewController
@synthesize messagesTableView;
@synthesize searchBar;
@synthesize filterViewController;
@synthesize filterNavigationViewController;
@synthesize filterPopoverController;

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
	self.title = NSLocalizedString(@"Mail", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)] autorelease];
	}
	else
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)] autorelease];
//	else
//		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadMessages];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	self.messagesTableView = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	[messages release];
	[filteredValues release];
	messages = filteredValues = nil;
	[mailBox release];
	mailBox = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[messagesTableView release];
	[searchBar release];
	[filteredValues release];
	[messages release];
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[mailBox release];
    [super dealloc];
}

- (IBAction)markAsRead:(id)sender {
	for (EUMailMessage* message in [messages objectAtIndex:0])
		message.read = YES;
	[mailBox save];
	[messagesTableView reloadData];
	[self.searchDisplayController.searchResultsTableView reloadData];
	[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:mailBox];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.searchDisplayController.searchResultsTableView == tableView)
		return [[filteredValues objectAtIndex:section] count];
	else {
		return [[messages objectAtIndex:section] count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"MessageCellView";
	
    MessageCellView *cell = (MessageCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == messagesTableView ? @"MessageCellView" : @"MessageCellViewCompact";
		else
			nibName = @"MessageCellView";
		
        cell = [MessageCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	EUMailMessage *message;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		message = [[filteredValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	else {
		message = [[messages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	}
	UIFont* font = [UIFont fontWithName:message.read ? @"Helvetica" : @"Helvetica-Bold" size:cell.subjectLabel.font.pointSize];
	UIColor* color = message.read ? [UIColor lightTextColor] : [UIColor whiteColor];
	cell.subjectLabel.text = message.header.title;
	cell.fromLabel.text = [NSString stringWithFormat:@"%@ -> %@", message.from, message.to];

	cell.subjectLabel.font = font;
	cell.subjectLabel.textColor = color;
	cell.fromLabel.font = font;
	cell.fromLabel.textColor = color;
	cell.dateLabel.font = font;
	cell.dateLabel.textColor = color;
							
	cell.dateLabel.text = message.date;
	
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 0 ? @"Inbox" : @"Sent";
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 40, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == messagesTableView ? 32 : 54;
	else
		return 54;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	EUMailMessage* message = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		message = [[filteredValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	else
		message = [[messages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+LoadMessage" name:NSLocalizedString(@"Loading Message Body", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[message text];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			MessageViewController *controller = [[MessageViewController alloc] initWithNibName:@"MessageViewController" bundle:nil];
			controller.message = message;
			
			if (!message.read && message.text) {
				message.read = YES;
				[mailBox save];
				[self.messagesTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
				[self.searchDisplayController.searchResultsTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
				[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:mailBox];
			}
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
				navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
				navController.modalPresentationStyle = UIModalPresentationFormSheet;
				[controller.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
				[self presentModalViewController:navController animated:YES];
				[navController release];
			}
			else
				[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
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
	tableView.backgroundColor = [UIColor clearColor];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		tableView.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]] autorelease];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[filterPopoverController presentPopoverFromRect:searchBar.frame inView:[searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:filterNavigationViewController animated:YES];
}

#pragma mark FilterViewControllerDelegate
- (void) filterViewController:(FilterViewController*) controller didApplyFilter:(EUFilter*) filter {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[self dismissModalViewControllerAnimated:YES];
	[self reloadMessages];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation MessagesViewController(Private)

- (void) reloadMessages {
	[messages release];
	messages = nil;
	if (!mailBox) {
		EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mailMessagesFilter" ofType:@"plist"]]];
		__block EUMailBox* mailBoxTmp = nil;
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Load" name:NSLocalizedString(@"Loading Messages", nil)];
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			//mailBoxTmp = [[EUMailBox alloc] initWithAccount:[EVEAccount currentAccount]];
			mailBoxTmp = [[[EVEAccount currentAccount] mailBox] retain];
			if (!mailBoxTmp.inbox) {
				NSError* error = mailBoxTmp ? mailBoxTmp.error : [NSError errorWithDomain:@"Neocom" code:0 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown error", nil) forKey:NSLocalizedDescriptionKey]];
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				[mailBoxTmp release];
				mailBoxTmp = nil;
			}
			else {
				[filterTmp updateWithValues:mailBoxTmp.inbox];
				[filterTmp updateWithValues:mailBoxTmp.sent];
			}
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![operation isCancelled]) {
				[mailBox release];
				mailBox = mailBoxTmp;
				if (mailBox)
					[self reloadMessages];
				[filter release];
				filter = [filterTmp retain];
			}
			else {
				[mailBoxTmp release];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		NSMutableArray* messagesTmp = [NSMutableArray array];
		if (filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[messagesTmp addObject:[filter applyToValues:mailBox.inbox]];
				[messagesTmp addObject:[filter applyToValues:mailBox.sent]];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					[messages release];
					messages = [messagesTmp retain];
					[self searchWithSearchString:self.searchBar.text];
					[messagesTableView reloadData];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			messages = [[NSArray alloc] initWithObjects:mailBox.inbox, mailBox.sent, nil];
		}
	}
	[messagesTableView reloadData];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[messages release];
			[filteredValues release];
			messages = filteredValues = nil;
			[mailBox release];
			mailBox = nil;
			[filter release];
			filter = nil;
			[self reloadMessages];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		[messages release];
		[filteredValues release];
		messages = filteredValues = nil;
		[mailBox release];
		mailBox = nil;
		[filter release];
		filter = nil;
		[self reloadMessages];
	}
}

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (messages.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSArray* section in messages) {
			NSMutableArray* filteredSection = [NSMutableArray array];
			for (EUMailMessage *message in section) {
				if (([message.header.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.from rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.to rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[filteredSection addObject:message];
			}
			[filteredValuesTmp addObject:filteredSection];
		}
/*		for (NSDictionary *message in messages) {
			if (([message valueForKeyPath:@"header.title"] && [[message valueForKeyPath:@"header.title"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([message valueForKey:@"from"] && [[message valueForKey:@"from"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([message valueForKey:@"to"] && [[message valueForKey:@"to"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
				[filteredValuesTmp addObject:message];
		}*/
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[filteredValues release];
			filteredValues = [filteredValuesTmp retain];
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
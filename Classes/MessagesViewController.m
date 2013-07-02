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

@interface MessagesViewController()
@property(nonatomic, strong) NSMutableArray *filteredValues;
@property(nonatomic, strong) NSArray *messages;
@property(nonatomic, strong) EUFilter *filter;
@property(nonatomic, strong) EUMailBox* mailBox;

- (void) reloadMessages;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (IBAction)onClose:(id)sender;
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
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	self.title = NSLocalizedString(@"Mail", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		//[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
		//self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)] autorelease];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.toolbar];
	}
	else
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark as read", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(markAsRead:)];
//	else
//		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	[self reloadMessages];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
	[self setToolbar:nil];
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	self.messages = nil;
	self.filteredValues = nil;
	self.mailBox = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)markAsRead:(id)sender {
	for (EUMailMessage* message in [self.messages objectAtIndex:0])
		message.read = YES;
	[self.mailBox save];
	[self.tableView reloadData];
	[self.searchDisplayController.searchResultsTableView reloadData];
	[[NSNotificationCenter defaultCenter] postNotificationName:NotificationReadMail object:self.mailBox];
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
		return [[self.filteredValues objectAtIndex:section] count];
	else {
		return [[self.messages objectAtIndex:section] count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"MessageCellView";
	
    MessageCellView *cell = (MessageCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == self.tableView ? @"MessageCellView" : @"MessageCellViewCompact";
		else
			nibName = @"MessageCellView";
		
        cell = [MessageCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	EUMailMessage *message;
	
	if (self.searchDisplayController.searchResultsTableView == tableView)
		message = [[self.filteredValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	else {
		message = [[self.messages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 22)];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 40, 22)];
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
		return tableView == self.tableView ? 32 : 54;
	else
		return 54;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	EUMailMessage* message = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
		message = [[self.filteredValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	else
		message = [[self.messages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+LoadMessage" name:NSLocalizedString(@"Loading Message Body", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		[message text];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
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
				[controller.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)]];
				[self presentModalViewController:navController animated:YES];
			}
			else
				[self.navigationController pushViewController:controller animated:YES];
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
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundPopover~ipad.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	else
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	self.filterViewController.filter = self.filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.filterPopoverController presentPopoverFromRect:self.searchBar.frame inView:[self.searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:self.filterNavigationViewController animated:YES];
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

#pragma mark - Private

- (void) reloadMessages {
	self.messages = nil;
	if (!self.mailBox) {
		EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mailMessagesFilter" ofType:@"plist"]]];
		__block EUMailBox* mailBoxTmp = nil;
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Load" name:NSLocalizedString(@"Loading Messages", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^(void) {
			mailBoxTmp = [[EVEAccount currentAccount] mailBox];
			if (!mailBoxTmp.inbox) {
				NSError* error = mailBoxTmp ? mailBoxTmp.error : [NSError errorWithDomain:@"Neocom" code:0 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown error", nil) forKey:NSLocalizedDescriptionKey]];
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				mailBoxTmp = nil;
			}
			else {
				[filterTmp updateWithValues:mailBoxTmp.inbox];
				[filterTmp updateWithValues:mailBoxTmp.sent];
			}
		}];
		
		[operation setCompletionBlockInCurrentThread:^{
			if (![weakOperation isCancelled]) {
				self.mailBox = mailBoxTmp;
				if (self.mailBox)
					[self reloadMessages];
				self.filter = filterTmp;
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else {
		NSMutableArray* messagesTmp = [NSMutableArray array];
		if (self.filter) {
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				[messagesTmp addObject:[self.filter applyToValues:self.mailBox.inbox]];
				[messagesTmp addObject:[self.filter applyToValues:self.mailBox.sent]];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![weakOperation isCancelled]) {
					self.messages = messagesTmp;
					[self searchWithSearchString:self.searchBar.text];
					[self.tableView reloadData];
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			self.messages = [[NSArray alloc] initWithObjects:self.mailBox.inbox, self.mailBox.sent, nil];
		}
	}
	[self.tableView reloadData];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.messages = nil;
			self.filteredValues = nil;
			self.mailBox = nil;
			self.filter = nil;
			[self reloadMessages];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		self.messages = nil;
		self.filteredValues = nil;
		self.mailBox = nil;
		self.filter = nil;
		[self reloadMessages];
	}
}

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (self.messages.count == 0 || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"MessagesViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSArray* section in self.messages) {
			NSMutableArray* filteredSection = [NSMutableArray array];
			for (EUMailMessage *message in section) {
				if (([message.header.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.from rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
					([message.to rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
					[filteredSection addObject:message];
			}
			[filteredValuesTmp addObject:filteredSection];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.filteredValues = filteredValuesTmp;
			[self.searchDisplayController.searchResultsTableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
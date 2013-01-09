//
//  WalletJournalViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WalletJournalViewController.h"
#import "EVEOnlineAPI.h"
#import "UIAlertView+Error.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "WalletJournalCellView.h"
#import "UITableViewCell+Nib.h"
#import "SelectCharacterBarButtonItem.h"
#import "ItemViewController.h"

#define JOURNAL_ROWS_COUNT 200

@interface WalletJournalViewController(Private)
- (void) reloadJournal;
- (NSMutableArray*) downloadWalletJournalWithAccountIndex:(NSInteger) accountIndex;
- (void) downloadAccountBalance;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
- (NSMutableDictionary*) refTypes;
@end


@implementation WalletJournalViewController
@synthesize walletJournalTableView;
@synthesize ownerSegmentControl;
@synthesize accountSegmentControl;
@synthesize accountsView;
@synthesize ownerToolbar;
@synthesize accountToolbar;
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
	self.title = NSLocalizedString(@"Wallet Journal", nil);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:searchBar] autorelease]];
		//[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithCustomView:ownerSegmentControl] autorelease]];
		self.navigationItem.titleView = ownerSegmentControl;
		self.filterPopoverController = [[[UIPopoverController alloc] initWithContentViewController:filterNavigationViewController] autorelease];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
	
	[ownerSegmentControl layoutSubviews];
	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletJournalOwner];
	accountSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletJournalCorpAccount];
	
	[self reloadJournal];
	[self downloadAccountBalance];
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
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	self.walletJournalTableView = nil;
	self.ownerSegmentControl = nil;
	self.accountSegmentControl = nil;
	self.accountsView = nil;
	self.ownerToolbar = nil;
	self.accountToolbar = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	
	[walletJournal release];
	[charWalletJournal release];
	[corpWalletJournal release];
	[filteredValues release];
	[corpAccounts release];
	[characterBalance release];
	[charFilter release];
	[corpFilter release];
	[refTypes release];
	
	walletJournal = nil;
	charWalletJournal = nil;
	corpWalletJournal = nil;
	filteredValues = nil;
	corpAccounts = nil;
	characterBalance = nil;
	charFilter = corpFilter = nil;
	refTypes = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[walletJournalTableView release];
	[ownerSegmentControl release];
	[accountSegmentControl release];
	[accountsView release];
	[ownerToolbar release];
	[accountToolbar release];
	[searchBar release];
	
	[walletJournal release];
	[charWalletJournal release];
	[corpWalletJournal release];
	[filteredValues release];
	[corpAccounts release];
	[characterBalance release];
	
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
	[refTypes release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsWalletJournalOwner];
	
	[walletJournalTableView reloadData];
	[self reloadJournal];
	
	[UIView beginAnimations:0 context:0];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (ownerSegmentControl.selectedSegmentIndex == 1) {
			accountToolbar.frame = CGRectMake(0, 0, accountToolbar.frame.size.width, accountToolbar.frame.size.height);
			walletJournalTableView.frame = CGRectMake(0, accountToolbar.frame.size.height, walletJournalTableView.frame.size.width, walletJournalTableView.frame.size.height);
		}
		else {
			accountToolbar.frame = CGRectMake(0, -accountToolbar.frame.size.height, accountToolbar.frame.size.width, accountToolbar.frame.size.height);
			walletJournalTableView.frame = CGRectMake(0, 0, walletJournalTableView.frame.size.width, walletJournalTableView.frame.size.height);
		}
	}
	else {
		if (ownerSegmentControl.selectedSegmentIndex == 1) {
			accountsView.frame = CGRectMake(0, 88, 320, 44);
			walletJournalTableView.frame = CGRectMake(0, 132, 320, self.view.frame.size.height);
			walletJournalTableView.topView.frame = CGRectMake(0, 0, 320, 132);
		}
		else {
			accountsView.frame = CGRectMake(0, 44, 320, 44);
			walletJournalTableView.frame = CGRectMake(0, 88, 320, self.view.frame.size.height);
			walletJournalTableView.topView.frame = CGRectMake(0, 0, 320, 88);
		}
	}
	[UIView commitAnimations];
}

- (IBAction) onChangeAccount:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:accountSegmentControl.selectedSegmentIndex forKey:SettingsWalletJournalCorpAccount];
	
	[walletJournalTableView reloadData];
	[self reloadJournal];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	@synchronized(self) {
		if (self.searchDisplayController.searchResultsTableView == tableView)
			return filteredValues.count;
		else {
			return walletJournal.count;
		}
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		row = [filteredValues objectAtIndex:indexPath.row];
	else {
		row = [walletJournal objectAtIndex:indexPath.row];
	}

    NSString *cellIdentifier;
	if ([row valueForKey:@"tax"])
		cellIdentifier = @"WalletJournalCellViewTax";
	else
		cellIdentifier = @"WalletJournalCellView";
    
    WalletJournalCellView *cell = (WalletJournalCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == walletJournalTableView ? @"WalletJournalCellView" : @"WalletJournalCellViewCompact";
		else
			nibName = @"WalletJournalCellView";
		
        cell = [WalletJournalCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	
	cell.dateLabel.text = [row valueForKey:@"date"];
	cell.amountLabel.text = [row valueForKey:@"amount"];
	cell.balanceLabel.text = [row valueForKey:@"balance"];
	cell.titleLabel.text = [row valueForKey:@"title"];
	cell.nameLabel.text = [row valueForKey:@"name"];
	cell.taxLabel.text = [row valueForKey:@"tax"];
	cell.amountLabel.textColor = [[row valueForKey:@"outgo"] boolValue] ? [UIColor redColor] : [UIColor greenColor];
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSNumber *balance = nil;
	
	@synchronized(self) {
		if (ownerSegmentControl.selectedSegmentIndex == 0)
			balance = [[characterBalance retain] autorelease];
		else {
			if (corpAccounts.count > accountSegmentControl.selectedSegmentIndex)
				balance = [corpAccounts objectAtIndex:accountSegmentControl.selectedSegmentIndex];
		}
		[[balance retain] autorelease];
	}
	
	if (balance)
		return [NSString stringWithFormat:NSLocalizedString(@"Balance: %@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:balance numberStyle:NSNumberFormatterDecimalStyle]];
	else
		return @"";
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
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
	NSDictionary *row;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		row = [filteredValues objectAtIndex:indexPath.row];
	else {
		row = [walletJournal objectAtIndex:indexPath.row];
	}
	
	NSDictionary* tax = [row valueForKey:@"tax"];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tax)
			return tableView == walletJournalTableView ? 36 : 91;
		else
			return tableView == walletJournalTableView ? 36 : 73;
	}
	else {
		return tax ? 91 : 73;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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
	}
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	BOOL corporate = (ownerSegmentControl.selectedSegmentIndex == 1);
	EUFilter *filter = corporate ? corpFilter : charFilter;
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
	[self reloadJournal];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation WalletJournalViewController(Private)

- (void) reloadJournal {
	EVEAccount *account = [EVEAccount currentAccount];
	isFail = NO;
	BOOL corporate = ownerSegmentControl.selectedSegmentIndex == 1;
	[walletJournal release];
	walletJournal = nil;
	if (!corporate) {
		if (!charWalletJournal) {
			charWalletJournal = [[NSMutableArray alloc] init];
			NSMutableArray *charWalletJournalTmp = [NSMutableArray array];
			EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletJournalFilter" ofType:@"plist"]]];
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CharacterWallet" name:NSLocalizedString(@"Loading Character Journal", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSError *error = nil;
				
				if (!account) {
					[pool release];
					return;
				}
				
				EVECharWalletJournal *journal = [EVECharWalletJournal charWalletJournalWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID fromID:0 rowCount:JOURNAL_ROWS_COUNT error:&error];
				operation.progress = 0.5;
				if (error) {
					[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				}
				else {
					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
					
					float n = journal.charWalletJournal.count;
					float i = 0;
					for (EVECharWalletJournalItem *transaction in journal.charWalletJournal) {
						operation.progress = 0.5 + i++ / n / 2;
						NSString* name = nil;
						if (transaction.ownerName2.length > 0)
							name = [NSString stringWithFormat:@"%@ -> %@", transaction.ownerName1, transaction.ownerName2];
						else
							name = transaction.ownerName1;
						NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
													[dateFormatter stringFromDate:transaction.date], @"date",
													[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.amount + transaction.taxAmount] numberStyle:NSNumberFormatterDecimalStyle]], @"amount",
													[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.balance] numberStyle:NSNumberFormatterDecimalStyle]], @"balance",
													transaction.amount < 0 ? NSLocalizedString(@"Outgo", nil) : NSLocalizedString(@"Income", nil), @"direction",
													[NSNumber numberWithBool:transaction.amount < 0], @"outgo",
													nil];
						if (name)
							[row setValue:name forKey:@"name"];
						NSDictionary* refTypesDic = [self refTypes];
						EVERefTypesItem* refType = [refTypesDic valueForKey:[NSString stringWithFormat:@"%d", transaction.refTypeID]];
						if (refType)
							[row setValue:refType.refTypeName forKey:@"title"];
						else
							[row setValue:[NSString stringWithFormat:NSLocalizedString(@"Unknown refTypeID %d", nil), transaction.refTypeID]  forKey:@"title"];
						
						if (transaction.taxAmount > 0) {
							NSMutableString *tax = [NSMutableString stringWithFormat:NSLocalizedString(@"-%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInteger:transaction.taxAmount] numberStyle:NSNumberFormatterDecimalStyle]];
							if (transaction.amount > 0)
								[tax appendFormat:@" (%d%%)", (int)(transaction.taxAmount / (transaction.amount + transaction.taxAmount) * 100)];
							[row setValue:tax forKey:@"tax"];
						}
						
						if (transaction.ownerName1.length > 0)
							[row setValue:transaction.ownerName1 forKey:@"ownerName1"];
						if (transaction.ownerName2.length > 0)
							[row setValue:transaction.ownerName2 forKey:@"ownerName2"];
						
						[charWalletJournalTmp addObject:row];
					}
					[dateFormatter release];
					[filterTmp updateWithValues:charWalletJournalTmp];
					[charWalletJournalTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
				}
				[pool release];
			}];
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					[charFilter release];
					charFilter = [filterTmp retain];
					[charWalletJournal addObjectsFromArray:charWalletJournalTmp];
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[self reloadJournal];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *journalTmp = [NSMutableArray array];
			if (charFilter) {
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				[operation addExecutionBlock:^(void) {
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[journalTmp addObjectsFromArray:[charFilter applyToValues:charWalletJournal]];
					[pool release];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![operation isCancelled]) {
						if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							[walletJournal release];
							walletJournal = [journalTmp retain];
							[self searchWithSearchString:self.searchBar.text];
							[walletJournalTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				walletJournal = [journalTmp retain];
		}
	}
	
	else {
		if ((NSNull*) [corpWalletJournal objectAtIndex:accountSegmentControl.selectedSegmentIndex] == [NSNull null]) {
			if ((NSNull*) [corpWalletJournal objectAtIndex:0] == [NSNull null])
				[corpWalletJournal replaceObjectAtIndex:0 withObject:[NSMutableArray array]];
			
			NSMutableIndexSet *accountsToLoad = [NSMutableIndexSet indexSet];
			
			if (accountSegmentControl.selectedSegmentIndex > 0) {
				[accountsToLoad addIndex:accountSegmentControl.selectedSegmentIndex];
			}
			else {
				for (int i = 1; i <= 7; i++) {
					if ((NSNull*) [corpWalletJournal objectAtIndex:i] == [NSNull null]) {
						[corpWalletJournal replaceObjectAtIndex:i withObject:[NSMutableArray array]];
						[accountsToLoad addIndex:i];
					}
				}
			}
			
			NSMutableArray *corpWalletTransactionsTmp = [NSMutableArray arrayWithArray:corpWalletJournal];
			EUFilter *filter = corpFilter ? [[corpFilter copy] autorelease] : [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletJournalFilter" ofType:@"plist"]]];
			
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CorpWallet" name:NSLocalizedString(@"Loading Corp Journal", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSOperationQueue *queue = [[NSOperationQueue alloc] init];
				NSMutableArray *account0 = [NSMutableArray arrayWithArray:[corpWalletTransactionsTmp objectAtIndex:0]];

				float n = accountsToLoad.count;
				__block float i = 0;
				[accountsToLoad enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					NSMutableArray *account = [NSMutableArray array];
					EUOperation *loadingOperation = [EUOperation operationWithIdentifier:nil name:NSLocalizedString(@"Loading Journal Details", nil)];
					[loadingOperation addExecutionBlock:^{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						[account addObjectsFromArray:[self downloadWalletJournalWithAccountIndex:idx]];
						[pool release];
					}];
					
					[loadingOperation setCompletionBlockInCurrentThread:^(void) {
						operation.progress = i++ / n;
						[filter updateWithValues:account];
						[corpWalletTransactionsTmp replaceObjectAtIndex:idx withObject:account];
						[account0 addObjectsFromArray:account];
					}];
					
					[queue addOperation:loadingOperation];
				}];
				
				[queue waitUntilAllOperationsAreFinished];
				[account0 sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
				[corpWalletTransactionsTmp replaceObjectAtIndex:0 withObject:account0];
				
				[queue release];
				[pool release];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				[corpWalletJournal release];
				corpWalletJournal = [corpWalletTransactionsTmp retain];
				[corpFilter release];
				corpFilter = [filter retain];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
					[self reloadJournal];
				}
			}];
			
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *journalTmp = [NSMutableArray array];
			if (corpFilter) {
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				[operation addExecutionBlock:^(void) {
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[journalTmp addObjectsFromArray:[corpFilter applyToValues:[corpWalletJournal objectAtIndex:accountSegmentControl.selectedSegmentIndex]]];
					[pool release];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![operation isCancelled]) {
						if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							[walletJournal release];
							walletJournal = [journalTmp retain];
							[self searchWithSearchString:self.searchBar.text];
							[walletJournalTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				walletJournal = [[corpWalletJournal objectAtIndex:accountSegmentControl.selectedSegmentIndex] retain];
		}
	}
	[walletJournalTableView reloadData];
}

- (NSMutableArray*) downloadWalletJournalWithAccountIndex:(NSInteger) accountIndex {
	NSInteger accountKey = accountIndex + 999;
	NSMutableArray *currentAccount = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	NSError *error = nil;
	
	if (!account)
		return currentAccount;
	
	EVECorpWalletJournal *journal = [EVECorpWalletJournal corpWalletJournalWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID accountKey:accountKey fromID:0 rowCount:JOURNAL_ROWS_COUNT error:&error];
	//[EVECorpWalletTransactions corpWalletTransactionsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID beforeTransID:0 accountKey:accountKey error:&error];
	if (error) {
		@synchronized(self) {
			if (!isFail)
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			isFail = YES;
		}
	}
	else {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
		
		for (EVECorpWalletJournalItem *transaction in journal.corpWalletJournal) {
			NSString* name = nil;
			if (transaction.ownerName2.length > 0)
				name = [NSString stringWithFormat:@"%@ -> %@", transaction.ownerName1, transaction.ownerName2];
			else
				name = transaction.ownerName1;
			
			NSMutableDictionary* row = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[dateFormatter stringFromDate:transaction.date], @"date",
										[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.amount] numberStyle:NSNumberFormatterDecimalStyle]], @"amount",
										[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.balance] numberStyle:NSNumberFormatterDecimalStyle]], @"balance",
										transaction.amount < 0 ? NSLocalizedString(@"Outgo", nil) : NSLocalizedString(@"Income", nil), @"direction",
										[NSNumber numberWithBool:transaction.amount < 0], @"outgo",
										nil];
			if (name)
				[row setValue:name forKey:@"name"];
			NSDictionary* refTypesDic = [self refTypes];
			EVERefTypesItem* refType = [refTypesDic valueForKey:[NSString stringWithFormat:@"%d", transaction.refTypeID]];
			if (refType)
				[row setValue:refType.refTypeName forKey:@"title"];
			else
				[row setValue:[NSString stringWithFormat:NSLocalizedString(@"Unknown refTypeID %d", nil), transaction.refTypeID] forKey:@"title"];

			if (transaction.ownerName1.length > 0)
				[row setValue:transaction.ownerName1 forKey:@"ownerName1"];
			if (transaction.ownerName2.length > 0)
				[row setValue:transaction.ownerName2 forKey:@"ownerName2"];

			[currentAccount addObject:row];
		}
		[dateFormatter release];
		[currentAccount sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
	}
	return currentAccount;
}

- (void) downloadAccountBalance {
	NSMutableArray *corpAccountsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CorpAccountBalance" name:NSLocalizedString(@"Loading Account Balance", nil)];
	__block NSNumber *characterBalanceTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		characterBalanceTmp = [[NSNumber numberWithFloat:account.characterSheet.balance] retain];
		
		NSError *error = nil;
		EVEAccountBalance *accountBalance = [EVEAccountBalance accountBalanceWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:YES error:&error];
		if (!error) {
			float summary = 0;
			[corpAccountsTmp addObject:[NSNull null]];
			for (EVEAccountBalanceItem *account in accountBalance.accounts) {
				summary += account.balance;
				[corpAccountsTmp addObject:[NSNumber numberWithFloat:account.balance]];
			}
			[corpAccountsTmp replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:summary]];
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[characterBalance release];
			characterBalance = characterBalanceTmp;
			[corpAccounts release];
			corpAccounts = [corpAccountsTmp retain];
			[walletJournalTableView reloadData];
		}
		else
			[characterBalanceTmp release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	isFail = NO;
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			@synchronized(self) {
				[walletJournal release];
				walletJournal = nil;
				[charWalletJournal release];
				charWalletJournal = nil;
				[corpWalletJournal release];
				corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
				[characterBalance release];
				characterBalance = nil;
				[corpAccounts release];
				corpAccounts = nil;
				[charFilter release];
				[corpFilter release];
				charFilter = corpFilter = nil;
			}
			[walletJournalTableView reloadData];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		@synchronized(self) {
			[walletJournal release];
			walletJournal = nil;
			[charWalletJournal release];
			charWalletJournal = nil;
			[corpWalletJournal release];
			corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
			[characterBalance release];
			characterBalance = nil;
			[corpAccounts release];
			corpAccounts = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
		}
		[walletJournalTableView reloadData];
		[self reloadJournal];
		[self downloadAccountBalance];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (!walletJournal || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *transcation in walletJournal) {
			if ([operation isCancelled])
				break;
			if (([transcation valueForKey:@"date"] && [[transcation valueForKey:@"date"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"title"] && [[transcation valueForKey:@"title"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"name"] && [[transcation valueForKey:@"name"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"direction"] && [[transcation valueForKey:@"direction"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredValuesTmp addObject:transcation];
			}
		}
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

- (NSMutableDictionary*) refTypes {
	@synchronized(self) {
		if (!refTypes) {
			refTypes = [[NSMutableDictionary alloc] init];
			EVERefTypes* eveRefTypes = [EVERefTypes refTypesWithError:nil];
			for (EVERefTypesItem* refType in eveRefTypes.refTypes) {
				[refTypes setValue:refType forKey:[NSString stringWithFormat:@"%d", refType.refTypeID]];
			}
		}
		return refTypes;
	}
}

@end

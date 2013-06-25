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

@interface WalletJournalViewController()
@property(nonatomic, strong) NSMutableArray *walletJournal;
@property(nonatomic, strong) NSMutableArray *charWalletJournal;
@property(nonatomic, strong) NSMutableArray *corpWalletJournal;
@property(nonatomic, strong) NSMutableArray *filteredValues;
@property(nonatomic, strong) NSMutableArray *corpAccounts;
@property(nonatomic, strong) NSNumber *characterBalance;
@property(nonatomic, assign, getter = isFail) BOOL fail;
@property(nonatomic, strong) EUFilter *charFilter;
@property(nonatomic, strong) EUFilter *corpFilter;
@property(nonatomic, strong) NSMutableDictionary* refTypes;

- (void) reloadJournal;
- (NSMutableArray*) downloadWalletJournalWithAccountIndex:(NSInteger) accountIndex;
- (void) downloadAccountBalance;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
@end


@implementation WalletJournalViewController

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
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
		self.navigationItem.titleView = self.ownerSegmentControl;
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	else
		[self.navigationItem setRightBarButtonItem:[SelectCharacterBarButtonItem barButtonItemWithParentViewController:self]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	self.corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
	
	[self.ownerSegmentControl setNeedsLayout];
	self.ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletJournalOwner];
	self.accountSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletJournalCorpAccount];
	
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	
	self.walletJournal = nil;
	self.charWalletJournal = nil;
	self.corpWalletJournal = nil;
	self.filteredValues = nil;
	self.corpAccounts = nil;
	self.characterBalance = nil;
	self.charFilter = nil;
	self.corpFilter = nil;
	self.refTypes = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.ownerSegmentControl.selectedSegmentIndex forKey:SettingsWalletJournalOwner];
	
	[self.walletJournalTableView reloadData];
	[self reloadJournal];
	
	[UIView beginAnimations:0 context:0];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (self.ownerSegmentControl.selectedSegmentIndex == 1) {
			self.accountToolbar.frame = CGRectMake(0, 0, self.accountToolbar.frame.size.width, self.accountToolbar.frame.size.height);
			self.walletJournalTableView.frame = CGRectMake(0, self.accountToolbar.frame.size.height, self.walletJournalTableView.frame.size.width, self.walletJournalTableView.frame.size.height);
		}
		else {
			self.accountToolbar.frame = CGRectMake(0, -self.accountToolbar.frame.size.height, self.accountToolbar.frame.size.width, self.accountToolbar.frame.size.height);
			self.walletJournalTableView.frame = CGRectMake(0, 0, self.walletJournalTableView.frame.size.width, self.walletJournalTableView.frame.size.height);
		}
	}
	else {
		if (self.ownerSegmentControl.selectedSegmentIndex == 1) {
			self.accountsView.frame = CGRectMake(0, 88, 320, 44);
			self.walletJournalTableView.frame = CGRectMake(0, 132, 320, self.view.frame.size.height);
			self.walletJournalTableView.topView.frame = CGRectMake(0, 0, 320, 132);
		}
		else {
			self.accountsView.frame = CGRectMake(0, 44, 320, 44);
			self.walletJournalTableView.frame = CGRectMake(0, 88, 320, self.view.frame.size.height);
			self.walletJournalTableView.topView.frame = CGRectMake(0, 0, 320, 88);
		}
	}
	[UIView commitAnimations];
}

- (IBAction) onChangeAccount:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.accountSegmentControl.selectedSegmentIndex forKey:SettingsWalletJournalCorpAccount];
	
	[self.walletJournalTableView reloadData];
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
			return self.filteredValues.count;
		else {
			return self.walletJournal.count;
		}
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *row;
	if (self.searchDisplayController.searchResultsTableView == tableView)
		row = [self.filteredValues objectAtIndex:indexPath.row];
	else {
		row = [self.walletJournal objectAtIndex:indexPath.row];
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
			nibName = tableView == self.walletJournalTableView ? @"WalletJournalCellView" : @"WalletJournalCellViewCompact";
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
		if (self.ownerSegmentControl.selectedSegmentIndex == 0)
			balance = self.characterBalance;
		else {
			if (self.corpAccounts.count > self.accountSegmentControl.selectedSegmentIndex)
				balance = [self.corpAccounts objectAtIndex:self.accountSegmentControl.selectedSegmentIndex];
		}
	}
	
	if (balance)
		return [NSString stringWithFormat:NSLocalizedString(@"Balance: %@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:balance numberStyle:NSNumberFormatterDecimalStyle]];
	else
		return @"";
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)];
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
		row = [self.filteredValues objectAtIndex:indexPath.row];
	else {
		row = [self.walletJournal objectAtIndex:indexPath.row];
	}
	
	NSDictionary* tax = [row valueForKey:@"tax"];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (tax)
			return tableView == self.walletJournalTableView ? 36 : 91;
		else
			return tableView == self.walletJournalTableView ? 36 : 73;
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
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background4.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTopLeft;
	}
	else {
		tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]];
		tableView.backgroundView.contentMode = UIViewContentModeTop;
	}
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar {
	BOOL corporate = (self.ownerSegmentControl.selectedSegmentIndex == 1);
	EUFilter *filter = corporate ? self.corpFilter : self.charFilter;
	self.filterViewController.filter = filter;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.filterPopoverController presentPopoverFromRect:self.searchBar.frame inView:[self.searchBar superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	else
		[self presentModalViewController:self.filterNavigationViewController animated:YES];
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

#pragma mark - Private

- (void) reloadJournal {
	EVEAccount *account = [EVEAccount currentAccount];
	self.fail = NO;
	BOOL corporate = self.ownerSegmentControl.selectedSegmentIndex == 1;
	self.walletJournal = nil;
	if (!corporate) {
		if (!self.charWalletJournal) {
			self.charWalletJournal = [[NSMutableArray alloc] init];
			NSMutableArray *charWalletJournalTmp = [NSMutableArray array];
			EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletJournalFilter" ofType:@"plist"]]];
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CharacterWallet" name:NSLocalizedString(@"Loading Character Journal", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				NSError *error = nil;
				
				if (!account)
					return;
				
				EVECharWalletJournal *journal = [EVECharWalletJournal charWalletJournalWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID fromID:0 rowCount:JOURNAL_ROWS_COUNT error:&error progressHandler:nil];
				weakOperation.progress = 0.5;
				if (error) {
					[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				}
				else {
					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
					[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
					
					float n = journal.charWalletJournal.count;
					float i = 0;
					for (EVECharWalletJournalItem *transaction in journal.charWalletJournal) {
						weakOperation.progress = 0.5 + i++ / n / 2;
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
					[filterTmp updateWithValues:charWalletJournalTmp];
					[charWalletJournalTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
				}
			}];
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![weakOperation isCancelled]) {
					self.charFilter = filterTmp;
					[self.charWalletJournal addObjectsFromArray:charWalletJournalTmp];
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[self reloadJournal];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *journalTmp = [NSMutableArray array];
			if (self.charFilter) {
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				__weak EUOperation* weakOperation = operation;
				[operation addExecutionBlock:^(void) {
					[journalTmp addObjectsFromArray:[self.charFilter applyToValues:self.charWalletJournal]];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![weakOperation isCancelled]) {
						if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							self.walletJournal = journalTmp;
							[self searchWithSearchString:self.searchBar.text];
							[self.walletJournalTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				self.walletJournal = journalTmp;
		}
	}
	
	else {
		if ((NSNull*) [self.corpWalletJournal objectAtIndex:self.accountSegmentControl.selectedSegmentIndex] == [NSNull null]) {
			if ((NSNull*) [self.corpWalletJournal objectAtIndex:0] == [NSNull null])
				[self.corpWalletJournal replaceObjectAtIndex:0 withObject:[NSMutableArray array]];
			
			NSMutableIndexSet *accountsToLoad = [NSMutableIndexSet indexSet];
			
			if (self.accountSegmentControl.selectedSegmentIndex > 0) {
				[accountsToLoad addIndex:self.accountSegmentControl.selectedSegmentIndex];
			}
			else {
				for (int i = 1; i <= 7; i++) {
					if ((NSNull*) [self.corpWalletJournal objectAtIndex:i] == [NSNull null]) {
						[self.corpWalletJournal replaceObjectAtIndex:i withObject:[NSMutableArray array]];
						[accountsToLoad addIndex:i];
					}
				}
			}
			
			NSMutableArray *corpWalletTransactionsTmp = [NSMutableArray arrayWithArray:self.corpWalletJournal];
			EUFilter *filter = self.corpFilter ? [self.corpFilter copy] : [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletJournalFilter" ofType:@"plist"]]];
			
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CorpWallet" name:NSLocalizedString(@"Loading Corp Journal", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				NSOperationQueue *queue = [[NSOperationQueue alloc] init];
				NSMutableArray *account0 = [NSMutableArray arrayWithArray:[corpWalletTransactionsTmp objectAtIndex:0]];

				float n = accountsToLoad.count;
				__block float i = 0;
				[accountsToLoad enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					NSMutableArray *account = [NSMutableArray array];
					EUOperation *loadingOperation = [EUOperation operationWithIdentifier:nil name:NSLocalizedString(@"Loading Journal Details", nil)];
					[loadingOperation addExecutionBlock:^{
						@autoreleasepool {
							[account addObjectsFromArray:[self downloadWalletJournalWithAccountIndex:idx]];
						}
					}];
					
					[loadingOperation setCompletionBlockInCurrentThread:^(void) {
						weakOperation.progress = i++ / n;
						[filter updateWithValues:account];
						[corpWalletTransactionsTmp replaceObjectAtIndex:idx withObject:account];
						[account0 addObjectsFromArray:account];
					}];
					
					[queue addOperation:loadingOperation];
				}];
				
				[queue waitUntilAllOperationsAreFinished];
				[account0 sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
				[corpWalletTransactionsTmp replaceObjectAtIndex:0 withObject:account0];
			}];
			
			[operation setCompletionBlockInCurrentThread:^(void) {
				self.corpWalletJournal = corpWalletTransactionsTmp;
				self.corpFilter = filter;
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
					[self reloadJournal];
				}
			}];
			
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *journalTmp = [NSMutableArray array];
			if (self.corpFilter) {
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				__weak EUOperation* weakOperation = operation;
				[operation addExecutionBlock:^(void) {
					[journalTmp addObjectsFromArray:[self.corpFilter applyToValues:[self.corpWalletJournal objectAtIndex:self.accountSegmentControl.selectedSegmentIndex]]];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![weakOperation isCancelled]) {
						if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							self.walletJournal = journalTmp;
							[self searchWithSearchString:self.searchBar.text];
							[self.walletJournalTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				self.walletJournal = [self.corpWalletJournal objectAtIndex:self.accountSegmentControl.selectedSegmentIndex];
		}
	}
	[self.walletJournalTableView reloadData];
}

- (NSMutableArray*) downloadWalletJournalWithAccountIndex:(NSInteger) accountIndex {
	NSInteger accountKey = accountIndex + 999;
	NSMutableArray *currentAccount = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	NSError *error = nil;
	
	if (!account)
		return currentAccount;
	
	EVECorpWalletJournal *journal = [EVECorpWalletJournal corpWalletJournalWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID accountKey:accountKey fromID:0 rowCount:JOURNAL_ROWS_COUNT error:&error progressHandler:nil];
	if (error) {
		@synchronized(self) {
			if (!self.fail)
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			self.fail = YES;
		}
	}
	else {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
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
		[currentAccount sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
	}
	return currentAccount;
}

- (void) downloadAccountBalance {
	NSMutableArray *corpAccountsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+CorpAccountBalance" name:NSLocalizedString(@"Loading Account Balance", nil)];
	__weak EUOperation* weakOperation = operation;
	__block NSNumber *characterBalanceTmp = nil;
	[operation addExecutionBlock:^(void) {
		characterBalanceTmp = [NSNumber numberWithFloat:account.characterSheet.balance];
		
		NSError *error = nil;
		EVEAccountBalance *accountBalance = [EVEAccountBalance accountBalanceWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:YES error:&error progressHandler:nil];
		if (!error) {
			float summary = 0;
			[corpAccountsTmp addObject:[NSNull null]];
			for (EVEAccountBalanceItem *account in accountBalance.accounts) {
				summary += account.balance;
				[corpAccountsTmp addObject:[NSNumber numberWithFloat:account.balance]];
			}
			[corpAccountsTmp replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:summary]];
		}
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.characterBalance = characterBalanceTmp;
			self.corpAccounts = corpAccountsTmp;
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) didSelectAccount:(NSNotification*) notification {
	EVEAccount *account = [EVEAccount currentAccount];
	self.fail = NO;
	if (!account) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			@synchronized(self) {
				self.walletJournal = nil;
				self.charWalletJournal = nil;
				self.corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
				self.characterBalance = nil;
				self.corpAccounts = nil;
				self.charFilter = nil;
				self.corpFilter = nil;
			}
			[self.walletJournalTableView reloadData];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		@synchronized(self) {
			self.walletJournal = nil;
			self.charWalletJournal = nil;
			self.corpWalletJournal  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
			self.characterBalance = nil;
			self.corpAccounts = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
		}
		[self.walletJournalTableView reloadData];
		[self reloadJournal];
		[self downloadAccountBalance];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (!self.walletJournal || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletJournalViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSDictionary *transcation in self.walletJournal) {
			if ([weakOperation isCancelled])
				break;
			if (([transcation valueForKey:@"date"] && [[transcation valueForKey:@"date"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"title"] && [[transcation valueForKey:@"title"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"name"] && [[transcation valueForKey:@"name"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"direction"] && [[transcation valueForKey:@"direction"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				[filteredValuesTmp addObject:transcation];
			}
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

- (NSMutableDictionary*) refTypes {
	@synchronized(self) {
		if (!_refTypes) {
			_refTypes = [[NSMutableDictionary alloc] init];
			EVERefTypes* eveRefTypes = [EVERefTypes refTypesWithError:nil progressHandler:nil];
			for (EVERefTypesItem* refType in eveRefTypes.refTypes) {
				[_refTypes setValue:refType forKey:[NSString stringWithFormat:@"%d", refType.refTypeID]];
			}
		}
		return _refTypes;
	}
}

@end

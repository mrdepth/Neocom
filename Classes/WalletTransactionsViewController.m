//
//  WalletTransactionsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WalletTransactionsViewController.h"
#import "EVEOnlineAPI.h"
#import "UIAlertView+Error.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "WalletTransactionCellView.h"
#import "UITableViewCell+Nib.h"
#import "SelectCharacterBarButtonItem.h"
#import "ItemViewController.h"

@interface WalletTransactionsViewController(Private)
- (void) reloadTransactions;
- (NSMutableArray*) downloadWalletTransactionsWithAccountIndex:(NSInteger) accountIndex;
- (void) downloadAccountBalance;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
@end


@implementation WalletTransactionsViewController
@synthesize walletTransactionsTableView;
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
	self.title = NSLocalizedString(@"Wallet Transactions", nil);
	
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
	corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];

	[ownerSegmentControl layoutSubviews];
	ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletTransactionsOwner];
	accountSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletTransactionsCorpAccount];
	
	[self reloadTransactions];
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
	self.walletTransactionsTableView = nil;
	self.ownerSegmentControl = nil;
	self.accountSegmentControl = nil;
	self.accountsView = nil;
	self.ownerToolbar = nil;
	self.accountToolbar = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	
	[walletTransactions release];
	[charWalletTransactions release];
	[corpWalletTransactions release];
	[filteredValues release];
	[corpAccounts release];
	[characterBalance release];
	[charFilter release];
	[corpFilter release];
	
	walletTransactions = nil;
	charWalletTransactions = nil;
	corpWalletTransactions = nil;
	filteredValues = nil;
	corpAccounts = nil;
	characterBalance = nil;
	charFilter = corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSelectAccount object:nil];
	[walletTransactionsTableView release];
	[ownerSegmentControl release];
	[accountSegmentControl release];
	[accountsView release];
	[ownerToolbar release];
	[accountToolbar release];
	[searchBar release];
	
	[walletTransactions release];
	[charWalletTransactions release];
	[corpWalletTransactions release];
	[filteredValues release];
	[corpAccounts release];
	[characterBalance release];
	
	[filterViewController release];
	[filterNavigationViewController release];
	[filterPopoverController release];
	[charFilter release];
	[corpFilter release];
    [super dealloc];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:ownerSegmentControl.selectedSegmentIndex forKey:SettingsWalletTransactionsOwner];
	
	[walletTransactionsTableView reloadData];
	[self reloadTransactions];
	
	[UIView beginAnimations:0 context:0];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (ownerSegmentControl.selectedSegmentIndex == 1) {
			accountToolbar.frame = CGRectMake(0, 0, accountToolbar.frame.size.width, accountToolbar.frame.size.height);
			walletTransactionsTableView.frame = CGRectMake(0, accountToolbar.frame.size.height, walletTransactionsTableView.frame.size.width, walletTransactionsTableView.frame.size.height);
		}
		else {
			accountToolbar.frame = CGRectMake(0, -accountToolbar.frame.size.height, accountToolbar.frame.size.width, accountToolbar.frame.size.height);
			walletTransactionsTableView.frame = CGRectMake(0, 0, walletTransactionsTableView.frame.size.width, walletTransactionsTableView.frame.size.height);
		}
	}
	else {
		if (ownerSegmentControl.selectedSegmentIndex == 1) {
			accountsView.frame = CGRectMake(0, 88, 320, 44);
			walletTransactionsTableView.frame = CGRectMake(0, 132, 320, self.view.frame.size.height);
			walletTransactionsTableView.topView.frame = CGRectMake(0, 0, 320, 132);
		}
		else {
			accountsView.frame = CGRectMake(0, 44, 320, 44);
			walletTransactionsTableView.frame = CGRectMake(0, 88, 320, self.view.frame.size.height);
			walletTransactionsTableView.topView.frame = CGRectMake(0, 0, 320, 88);
		}
	}
	[UIView commitAnimations];
}

- (IBAction) onChangeAccount:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:accountSegmentControl.selectedSegmentIndex forKey:SettingsWalletTransactionsCorpAccount];

	[walletTransactionsTableView reloadData];
	[self reloadTransactions];
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
			return walletTransactions.count;
		}
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
	cellIdentifier = @"WalletTransactionCellViewFull";
    
    WalletTransactionCellView *cell = (WalletTransactionCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSString *nibName;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			nibName = tableView == walletTransactionsTableView ? @"WalletTransactionCellView" : @"WalletTransactionCellViewCompact";
		else
			nibName = @"WalletTransactionCellView";
		
        cell = [WalletTransactionCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *transaction;
	
	@synchronized(self) {
		if (self.searchDisplayController.searchResultsTableView == tableView)
			transaction = [filteredValues objectAtIndex:indexPath.row];
		else {
			transaction = [walletTransactions objectAtIndex:indexPath.row];
		}
	}
	
	BOOL sell = [[transaction valueForKey:@"sell"] boolValue];
	cell.dateLabel.text = [transaction valueForKey:@"date"];
	cell.transactionAmmountLabel.text = [transaction valueForKey:@"transactionAmmount"];
	cell.locationLabel.text = [transaction valueForKey:@"stationName"];
	cell.priceLabel.text = [transaction valueForKey:@"price"];
	cell.typeNameLabel.text = [transaction valueForKey:@"typeName"];
	cell.characterLabel.text = [transaction valueForKey:@"characterName"];
	cell.iconImageView.image = [UIImage imageNamed:[transaction valueForKey:@"imageName"]];
	if (sell)
		cell.transactionAmmountLabel.textColor = [UIColor greenColor];
	else
		cell.transactionAmmountLabel.textColor = [UIColor redColor];
    
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == walletTransactionsTableView ? 53 : 72;
	else
		return 72;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[walletTransactions objectAtIndex:indexPath.row] valueForKey:@"type"];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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
	[self reloadTransactions];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

@end

@implementation WalletTransactionsViewController(Private)

- (void) reloadTransactions {
	EVEAccount *account = [EVEAccount currentAccount];
	isFail = NO;
	BOOL corporate = ownerSegmentControl.selectedSegmentIndex == 1;
	[walletTransactions release];
	walletTransactions = nil;
	if (!corporate) {
		if (!charWalletTransactions) {
			charWalletTransactions = [[NSMutableArray alloc] init];
			NSMutableArray *charWalletTransactionsTmp = [NSMutableArray array];
			EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletTransactionsFilter" ofType:@"plist"]]];
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CharacterWallet" name:NSLocalizedString(@"Loading Character Wallet", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSError *error = nil;
				
				if (!account) {
					[pool release];
					return;
				}
				
				EVECharWalletTransactions *transactions = [EVECharWalletTransactions charWalletTransactionsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID beforeTransID:0 error:&error];
				if (error) {
					[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
				}
				else {
					NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
					[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
					float n = transactions.transactions.count;
					float i = 0;
					for (EVECharWalletTransactionsItem *transaction in transactions.transactions) {
						operation.progress = 0.5 + i++ / n;
						EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:transaction.typeID error:nil];
						BOOL sell = [transaction.transactionType isEqualToString:@"sell"];
						[charWalletTransactionsTmp addObject:[NSDictionary dictionaryWithObjectsAndKeys:
															  [dateFormatter stringFromDate:transaction.transactionDateTime], @"date",
															  [NSString stringWithFormat:NSLocalizedString(@"%s%@ ISK", nil), sell ? "" : "-", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.price * transaction.quantity] numberStyle:NSNumberFormatterDecimalStyle]], @"transactionAmmount",
															  [NSString stringWithFormat:@"%@ (x%@)", transaction.typeName, [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.quantity] numberStyle:NSNumberFormatterDecimalStyle]], @"typeName",
															  transaction.stationName, @"stationName",
															  [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.price] numberStyle:NSNumberFormatterDecimalStyle]], @"price",
															  account.characterName, @"characterName",
															  [type typeSmallImageName], @"imageName",
															  type, @"type",
															  [NSNumber numberWithBool:sell], @"sell",
															  [transaction.transactionType capitalizedString], @"transactionType",
															  [NSNumber numberWithInteger:transaction.transactionID], @"transactionID",
															  nil]];
					}
					[dateFormatter release];
					[filterTmp updateWithValues:charWalletTransactionsTmp];
				}
				[charWalletTransactionsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
				[pool release];
			}];
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![operation isCancelled]) {
					[charFilter release];
					charFilter = [filterTmp retain];
					[charWalletTransactions addObjectsFromArray:charWalletTransactionsTmp];
					if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[self reloadTransactions];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *transactionsTmp = [NSMutableArray array];
			if (charFilter) {
				NSMutableArray* charWalletTransactionsLocal = charWalletTransactions;
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				[operation addExecutionBlock:^(void) {
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[transactionsTmp addObjectsFromArray:[charFilter applyToValues:charWalletTransactionsLocal]];
					[pool release];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![operation isCancelled]) {
						if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							[walletTransactions release];
							walletTransactions = [transactionsTmp retain];
							[self searchWithSearchString:self.searchBar.text];
							[walletTransactionsTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				walletTransactions = [transactionsTmp retain];
		}
	}
	
	else {
		if ((NSNull*) [corpWalletTransactions objectAtIndex:accountSegmentControl.selectedSegmentIndex] == [NSNull null]) {
			if ((NSNull*) [corpWalletTransactions objectAtIndex:0] == [NSNull null])
				[corpWalletTransactions replaceObjectAtIndex:0 withObject:[NSMutableArray array]];
			
			NSMutableIndexSet *accountsToLoad = [NSMutableIndexSet indexSet];
			
			if (accountSegmentControl.selectedSegmentIndex > 0) {
				[accountsToLoad addIndex:accountSegmentControl.selectedSegmentIndex];
			}
			else {
				for (int i = 1; i <= 7; i++) {
					if ((NSNull*) [corpWalletTransactions objectAtIndex:i] == [NSNull null]) {
						[corpWalletTransactions replaceObjectAtIndex:i withObject:[NSMutableArray array]];
						[accountsToLoad addIndex:i];
					}
				}
			}
			
			NSMutableArray *corpWalletTransactionsTmp = [NSMutableArray arrayWithArray:corpWalletTransactions];
			EUFilter *filter = corpFilter ? [[corpFilter copy] autorelease] : [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletTransactionsFilter" ofType:@"plist"]]];
			
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CorpWallet" name:NSLocalizedString(@"Loading Character Wallet", nil)];
			[operation addExecutionBlock:^(void) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSOperationQueue *queue = [[NSOperationQueue alloc] init];
				NSMutableArray *account0 = [NSMutableArray arrayWithArray:[corpWalletTransactionsTmp objectAtIndex:0]];

				float n = accountsToLoad.count;
				__block float i = 0;
				[accountsToLoad enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					NSMutableArray *account = [NSMutableArray array];
					EUOperation *loadingOperation = [EUOperation operation];
					[loadingOperation addExecutionBlock:^{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						[account addObjectsFromArray:[self downloadWalletTransactionsWithAccountIndex:idx]];
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
				[corpWalletTransactions release];
				corpWalletTransactions = [corpWalletTransactionsTmp retain];
				[corpFilter release];
				corpFilter = [filter retain];
				if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
					[self reloadTransactions];
				}
			}];
			
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *transactionsTmp = [NSMutableArray array];
			if (corpFilter) {
				NSMutableArray *corpWalletTransactionsLocal = corpWalletTransactions;
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				[operation addExecutionBlock:^(void) {
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[transactionsTmp addObjectsFromArray:[corpFilter applyToValues:[corpWalletTransactionsLocal objectAtIndex:accountSegmentControl.selectedSegmentIndex]]];
					[pool release];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![operation isCancelled]) {
						if ((ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							[walletTransactions release];
							walletTransactions = [transactionsTmp retain];
							[self searchWithSearchString:self.searchBar.text];
							[walletTransactionsTableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				walletTransactions = [[corpWalletTransactions objectAtIndex:accountSegmentControl.selectedSegmentIndex] retain];
		}
	}
	[walletTransactionsTableView reloadData];
}

- (NSMutableArray*) downloadWalletTransactionsWithAccountIndex:(NSInteger) accountIndex {
	NSInteger accountKey = accountIndex + 999;
	NSMutableArray *currentAccount = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	NSError *error = nil;
	
	if (!account)
		return currentAccount;
	
	EVECorpWalletTransactions *transactions = [EVECorpWalletTransactions corpWalletTransactionsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID beforeTransID:0 accountKey:accountKey error:&error];
	if (error) {
		@synchronized(self) {
			if (!isFail)
				[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			isFail = YES;
		}
	}
	else {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
		
		for (EVECorpWalletTransactionsItem *transaction in transactions.transactions) {
			
			EVEDBInvType *type = [EVEDBInvType invTypeWithTypeID:transaction.typeID error:nil];
			BOOL sell = [transaction.transactionType isEqualToString:@"sell"];
			[currentAccount addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   [dateFormatter stringFromDate:transaction.transactionDateTime], @"date",
									   [NSString stringWithFormat:NSLocalizedString(@"%s%@ ISK", nil), sell ? "" : "-", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.price * transaction.quantity] numberStyle:NSNumberFormatterDecimalStyle]], @"transactionAmmount",
									   [NSString stringWithFormat:@"%@ (x%@)", transaction.typeName, [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.quantity] numberStyle:NSNumberFormatterDecimalStyle]], @"typeName",
									   transaction.stationName, @"stationName",
									   [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:transaction.price] numberStyle:NSNumberFormatterDecimalStyle]], @"price",
									   [type typeSmallImageName], @"imageName",
									   type, @"type",
									   [NSNumber numberWithBool:sell], @"sell",
									   [transaction.transactionType capitalizedString], @"transactionType",
									   [NSNumber numberWithInteger:transaction.transactionID], @"transactionID",
									   transaction.characterName, @"characterName",
									   nil]];
		}
		[dateFormatter release];
		[currentAccount sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
	}
	return currentAccount;
}

- (void) downloadAccountBalance {
	NSMutableArray *corpAccountsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CorpAccountBalance" name:NSLocalizedString(@"Loading Corp Balance", nil)];
	__block NSNumber *characterBalanceTmp = nil;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		characterBalanceTmp = [[NSNumber numberWithFloat:account.characterSheet.balance] retain];
		
		NSError *error = nil;
		//EVEAccountBalance *accountBalance = [EVEAccountBalance accountBalanceWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID corporate:YES error:&error];
		EVEAccountBalance *accountBalance = [EVEAccountBalance accountBalanceWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID corporate:YES error:&error];
		if (!error) {
			float summary = 0;
			[corpAccountsTmp addObject:[NSNull null]];
			for (EVEAccountBalanceItem *account in accountBalance.accounts) {
				summary += account.balance;
				[corpAccountsTmp addObject:[NSNumber numberWithFloat:account.balance]];
			}
			[corpAccountsTmp replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:summary]];
			[walletTransactionsTableView reloadData];
		}
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[characterBalance release];
			characterBalance = characterBalanceTmp;
			[corpAccounts release];
			corpAccounts = [corpAccountsTmp retain];
			[walletTransactionsTableView reloadData];
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
				[walletTransactions release];
				walletTransactions = nil;
				[charWalletTransactions release];
				charWalletTransactions = nil;
				[corpWalletTransactions release];
				corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
				[characterBalance release];
				characterBalance = nil;
				[corpAccounts release];
				corpAccounts = nil;
				[charFilter release];
				[corpFilter release];
				charFilter = corpFilter = nil;
			}
			[walletTransactionsTableView reloadData];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		@synchronized(self) {
			[walletTransactions release];
			walletTransactions = nil;
			[charWalletTransactions release];
			charWalletTransactions = nil;
			[corpWalletTransactions release];
			corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
			[characterBalance release];
			characterBalance = nil;
			[corpAccounts release];
			corpAccounts = nil;
			[charFilter release];
			[corpFilter release];
			charFilter = corpFilter = nil;
		}
		[walletTransactionsTableView reloadData];
		[self reloadTransactions];
		[self downloadAccountBalance];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (!walletTransactions || !aSearchString)
		return;
	
	NSString *searchString = [[aSearchString copy] autorelease];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (NSDictionary *transcation in walletTransactions) {
			if ([operation isCancelled])
				break;
			if (([transcation valueForKey:@"date"] && [[transcation valueForKey:@"date"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"typeName"] && [[transcation valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"stationName"] && [[transcation valueForKey:@"stationName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"characterName"] && [[transcation valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
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

@end

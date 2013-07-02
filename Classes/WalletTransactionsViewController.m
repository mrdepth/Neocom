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

@interface WalletTransactionsViewController()
@property (nonatomic, strong) NSMutableArray *walletTransactions;
@property (nonatomic, strong) NSMutableArray *charWalletTransactions;
@property (nonatomic, strong) NSMutableArray *corpWalletTransactions;
@property (nonatomic, strong) NSMutableArray *filteredValues;
@property (nonatomic, strong) NSMutableArray *corpAccounts;
@property (nonatomic, strong) NSNumber *characterBalance;
@property (nonatomic, assign, getter = isFail) BOOL fail;
@property (nonatomic, strong) EUFilter *charFilter;
@property (nonatomic, strong) EUFilter *corpFilter;

- (void) reloadTransactions;
- (NSMutableArray*) downloadWalletTransactionsWithAccountIndex:(NSInteger) accountIndex;
- (void) downloadAccountBalance;
- (void) didSelectAccount:(NSNotification*) notification;
- (void) searchWithSearchString:(NSString*) searchString;
@end


@implementation WalletTransactionsViewController

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
	[self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]]];

	self.navigationItem.titleView = self.ownerSegmentControl;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
		self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterNavigationViewController];
		self.filterPopoverController.delegate = (FilterViewController*)  self.filterNavigationViewController.topViewController;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAccount:) name:NotificationSelectAccount object:nil];
	self.corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];

	[self.ownerSegmentControl layoutSubviews];
	self.ownerSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletTransactionsOwner];
	self.accountSegmentControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsWalletTransactionsCorpAccount];
	self.accountSegmentControl.enabled = self.ownerSegmentControl.selectedSegmentIndex == 1;

	
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.ownerSegmentControl = nil;
	self.accountSegmentControl = nil;
	self.searchBar = nil;
	self.filterPopoverController = nil;
	self.filterViewController = nil;
	self.filterNavigationViewController = nil;
	
	self.walletTransactions = nil;
	self.charWalletTransactions = nil;
	self.corpWalletTransactions = nil;
	self.filteredValues = nil;
	self.corpAccounts = nil;
	self.characterBalance = nil;
	self.charFilter = nil;
	self.corpFilter = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) onChangeOwner:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.ownerSegmentControl.selectedSegmentIndex forKey:SettingsWalletTransactionsOwner];
	
	[self.tableView reloadData];
	[self reloadTransactions];
	
	self.accountSegmentControl.enabled = self.ownerSegmentControl.selectedSegmentIndex == 1;
}

- (IBAction) onChangeAccount:(id) sender {
	[[NSUserDefaults standardUserDefaults] setInteger:self.accountSegmentControl.selectedSegmentIndex forKey:SettingsWalletTransactionsCorpAccount];

	[self.tableView reloadData];
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
			return self.filteredValues.count;
		else {
			return self.walletTransactions.count;
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
			nibName = tableView == self.tableView ? @"WalletTransactionCellView" : @"WalletTransactionCellViewCompact";
		else
			nibName = @"WalletTransactionCellView";
		
        cell = [WalletTransactionCellView cellWithNibName:nibName bundle:nil reuseIdentifier:cellIdentifier];
    }
	NSDictionary *transaction;
	
	@synchronized(self) {
		if (self.searchDisplayController.searchResultsTableView == tableView)
			transaction = [self.filteredValues objectAtIndex:indexPath.row];
		else {
			transaction = [self.walletTransactions objectAtIndex:indexPath.row];
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return tableView == self.tableView ? 53 : 72;
	else
		return 72;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
		controller.type = [[self.filteredValues objectAtIndex:indexPath.row] valueForKey:@"type"];
	else
		controller.type = [[self.walletTransactions objectAtIndex:indexPath.row] valueForKey:@"type"];
	[controller setActivePage:ItemViewControllerActivePageInfo];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:navController animated:YES];
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
	[self reloadTransactions];
}

- (void) filterViewControllerDidCancel:(FilterViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void) reloadTransactions {
	EVEAccount *account = [EVEAccount currentAccount];
	self.fail = NO;
	BOOL corporate = self.ownerSegmentControl.selectedSegmentIndex == 1;
	self.walletTransactions = nil;
	if (!corporate) {
		if (!self.charWalletTransactions) {
			self.charWalletTransactions = [[NSMutableArray alloc] init];
			NSMutableArray *charWalletTransactionsTmp = [NSMutableArray array];
			EUFilter *filterTmp = [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletTransactionsFilter" ofType:@"plist"]]];
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CharacterWallet" name:NSLocalizedString(@"Loading Character Wallet", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				NSError *error = nil;
				
				if (!account) {
					return;
				}
				
				EVECharWalletTransactions *transactions = [EVECharWalletTransactions charWalletTransactionsWithKeyID:account.charKeyID vCode:account.charVCode characterID:account.characterID beforeTransID:0 error:&error progressHandler:nil];
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
						weakOperation.progress = 0.5 + i++ / n;
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
					[filterTmp updateWithValues:charWalletTransactionsTmp];
				}
				[charWalletTransactionsTmp sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
			}];
			[operation setCompletionBlockInCurrentThread:^(void) {
				if (![weakOperation isCancelled]) {
					self.charFilter = filterTmp;
					[self.charWalletTransactions addObjectsFromArray:charWalletTransactionsTmp];
					if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
						[self reloadTransactions];
					}
				}
			}];
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *transactionsTmp = [NSMutableArray array];
			if (self.charFilter) {
				NSMutableArray* charWalletTransactionsLocal = self.charWalletTransactions;
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				__weak EUOperation* weakOperation = operation;
				[operation addExecutionBlock:^(void) {
					[transactionsTmp addObjectsFromArray:[self.charFilter applyToValues:charWalletTransactionsLocal]];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![weakOperation isCancelled]) {
						if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							self.walletTransactions = transactionsTmp;
							[self searchWithSearchString:self.searchBar.text];
							[self.tableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				self.walletTransactions = transactionsTmp;
		}
	}
	
	else {
		if ((NSNull*) [self.corpWalletTransactions objectAtIndex:self.accountSegmentControl.selectedSegmentIndex] == [NSNull null]) {
			if ((NSNull*) [self.corpWalletTransactions objectAtIndex:0] == [NSNull null])
				[self.corpWalletTransactions replaceObjectAtIndex:0 withObject:[NSMutableArray array]];
			
			NSMutableIndexSet *accountsToLoad = [NSMutableIndexSet indexSet];
			
			if (self.accountSegmentControl.selectedSegmentIndex > 0) {
				[accountsToLoad addIndex:self.accountSegmentControl.selectedSegmentIndex];
			}
			else {
				for (int i = 1; i <= 7; i++) {
					if ((NSNull*) [self.corpWalletTransactions objectAtIndex:i] == [NSNull null]) {
						[self.corpWalletTransactions replaceObjectAtIndex:i withObject:[NSMutableArray array]];
						[accountsToLoad addIndex:i];
					}
				}
			}
			
			NSMutableArray *corpWalletTransactionsTmp = [NSMutableArray arrayWithArray:self.corpWalletTransactions];
			EUFilter *filter = self.corpFilter ? [self.corpFilter copy] : [EUFilter filterWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"walletTransactionsFilter" ofType:@"plist"]]];
			
			__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CorpWallet" name:NSLocalizedString(@"Loading Character Wallet", nil)];
			__weak EUOperation* weakOperation = operation;
			[operation addExecutionBlock:^(void) {
				NSOperationQueue *queue = [[NSOperationQueue alloc] init];
				NSMutableArray *account0 = [NSMutableArray arrayWithArray:[corpWalletTransactionsTmp objectAtIndex:0]];

				float n = accountsToLoad.count;
				__block float i = 0;
				[accountsToLoad enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					NSMutableArray *account = [NSMutableArray array];
					EUOperation *loadingOperation = [EUOperation operation];
					[loadingOperation addExecutionBlock:^{
						@autoreleasepool {
							[account addObjectsFromArray:[self downloadWalletTransactionsWithAccountIndex:idx]];
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
				self.corpWalletTransactions = corpWalletTransactionsTmp;
				self.corpFilter = filter;
				if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
					[self reloadTransactions];
				}
			}];
			
			[[EUOperationQueue sharedQueue] addOperation:operation];
		}
		else {
			NSMutableArray *transactionsTmp = [NSMutableArray array];
			if (self.corpFilter) {
				NSMutableArray *corpWalletTransactionsLocal = self.corpWalletTransactions;
				__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Filter" name:NSLocalizedString(@"Applying Filter", nil)];
				__weak EUOperation* weakOperation = operation;
				[operation addExecutionBlock:^(void) {
					[transactionsTmp addObjectsFromArray:[self.corpFilter applyToValues:[corpWalletTransactionsLocal objectAtIndex:self.accountSegmentControl.selectedSegmentIndex]]];
				}];
				
				[operation setCompletionBlockInCurrentThread:^(void) {
					if (![weakOperation isCancelled]) {
						if ((self.ownerSegmentControl.selectedSegmentIndex == 1) == corporate) {
							self.walletTransactions = transactionsTmp;
							[self searchWithSearchString:self.searchBar.text];
							[self.tableView reloadData];
						}
					}
				}];
				[[EUOperationQueue sharedQueue] addOperation:operation];
			}
			else
				self.walletTransactions = [self.corpWalletTransactions objectAtIndex:self.accountSegmentControl.selectedSegmentIndex];
		}
	}
	[self.tableView reloadData];
}

- (NSMutableArray*) downloadWalletTransactionsWithAccountIndex:(NSInteger) accountIndex {
	NSInteger accountKey = accountIndex + 999;
	NSMutableArray *currentAccount = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	
	NSError *error = nil;
	
	if (!account)
		return currentAccount;
	
	EVECorpWalletTransactions *transactions = [EVECorpWalletTransactions corpWalletTransactionsWithKeyID:account.corpKeyID vCode:account.corpVCode characterID:account.characterID beforeTransID:0 accountKey:accountKey error:&error progressHandler:nil];
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
		[currentAccount sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
	}
	return currentAccount;
}

- (void) downloadAccountBalance {
	NSMutableArray *corpAccountsTmp = [NSMutableArray array];
	EVEAccount *account = [EVEAccount currentAccount];
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+CorpAccountBalance" name:NSLocalizedString(@"Loading Corp Balance", nil)];
	__weak EUOperation* weakOperation = operation;
	__block NSNumber *characterBalanceTmp = nil;
	[operation addExecutionBlock:^(void) {
		characterBalanceTmp = [NSNumber numberWithFloat:account.characterSheet.balance];
		
		NSError *error = nil;
		//EVEAccountBalance *accountBalance = [EVEAccountBalance accountBalanceWithUserID:character.userID apiKey:character.apiKey characterID:character.characterID corporate:YES error:&error];
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
			[self.tableView reloadData];
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
				self.walletTransactions = nil;
				self.charWalletTransactions = nil;
				self.corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
				self.characterBalance = nil;
				self.corpAccounts = nil;
				self.charFilter = nil;
				self.corpFilter = nil;
			}
			[self.tableView reloadData];
		}
		else
			[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else {
		@synchronized(self) {
			self.walletTransactions = nil;
			self.charWalletTransactions = nil;
			self.corpWalletTransactions  = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
			self.characterBalance = nil;
			self.corpAccounts = nil;
			self.charFilter = nil;
			self.corpFilter = nil;
		}
		[self.tableView reloadData];
		[self reloadTransactions];
		[self downloadAccountBalance];
	}
}

- (void) searchWithSearchString:(NSString*) aSearchString {
	if (!self.walletTransactions || !aSearchString)
		return;
	
	NSString *searchString = [aSearchString copy];
	NSMutableArray *filteredValuesTmp = [NSMutableArray array];

	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"WalletTransactionsViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		for (NSDictionary *transcation in self.walletTransactions) {
			if ([weakOperation isCancelled])
				break;
			if (([transcation valueForKey:@"date"] && [[transcation valueForKey:@"date"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"typeName"] && [[transcation valueForKey:@"typeName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"stationName"] && [[transcation valueForKey:@"stationName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) ||
				([transcation valueForKey:@"characterName"] && [[transcation valueForKey:@"characterName"] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {
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

@end

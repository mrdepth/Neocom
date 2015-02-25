//
//  NCWalletTransactionsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 18.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCWalletTransactionsViewController.h"
#import "EVEOnlineAPI.h"
#import "NCLocationsManager.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCWalletTransactionsCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCWalletTransactionsViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) id transaction;
@property (nonatomic, strong) NCLocationsManagerItem* location;
@property (nonatomic, strong) NCDBInvType* type;
@end

@interface NCWalletTransactionsViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* transactions;
@property (nonatomic, strong) NSString* accountName;
@property (nonatomic, strong) EVEAccountBalanceItem* balance;
@end

@interface NCWalletTransactionsViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* accounts;
@end

@implementation NCWalletTransactionsViewControllerDataRow

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.transaction = [aDecoder decodeObjectForKey:@"transaction"];
		self.location = [aDecoder decodeObjectForKey:@"location"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.transaction)
		[aCoder encodeObject:self.transaction forKey:@"transaction"];
	if (self.location)
		[aCoder encodeObject:self.location forKey:@"location"];
}

@end

@implementation NCWalletTransactionsViewControllerDataAccount

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.transactions = [aDecoder decodeObjectForKey:@"transactions"];
		self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
		self.balance = [aDecoder decodeObjectForKey:@"balance"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.transactions)
		[aCoder encodeObject:self.transactions forKey:@"transactions"];
	if (self.accountName)
		[aCoder encodeObject:self.accountName forKey:@"accountName"];
	if (self.balance)
		[aCoder encodeObject:self.balance forKey:@"balance"];
}

@end

@implementation NCWalletTransactionsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.accounts = [aDecoder decodeObjectForKey:@"accounts"];
		NSMutableDictionary* typesDic = [NSMutableDictionary new];
		
		for (NCWalletTransactionsViewControllerDataAccount* account in self.accounts) {
			for (NCWalletTransactionsViewControllerDataRow* row in account.transactions) {
				int32_t typeID = [row.transaction typeID];
				NCDBInvType* type = typesDic[@(typeID)];
				if (!type) {
					type = [NCDBInvType invTypeWithTypeID:typeID];
					if (type)
						typesDic[@(typeID)] = type;
				}
				row.type = type;
			}
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.accounts)
		[aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end

@interface NCWalletTransactionsViewController ()
@property (nonatomic, strong) NCWalletTransactionsViewControllerData* searchResults;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@end

@implementation NCWalletTransactionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		NCWalletTransactionsViewControllerDataRow* row = [sender object];
		controller.type = row.type;
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCWalletTransactionsViewControllerDataRow* row = [sender object];
		return row.type != nil;
	}
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return data.accounts.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[section];
	return account.transactions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[section];
	if (account.accountName)
		return [NSString stringWithFormat:@"%@: %@ ISK", account.accountName, [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
	else
		return [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
}


#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCWalletTransactionsViewControllerData* data = [NCWalletTransactionsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BOOL corporate = account.accountType == NCAccountTypeCorporate;

											 EVEAccountBalance* balance = [EVEAccountBalance accountBalanceWithKeyID:account.apiKey.keyID
																											   vCode:account.apiKey.vCode
																										 cachePolicy:cachePolicy
																										 characterID:account.characterID
																										   corporate:corporate
																											   error:&error
																									 progressHandler:^(CGFloat progress, BOOL *stop) {
																										 if ([task isCancelled])
																											 *stop = YES;
																									 }];
											 
											 NSMutableSet* locationsIDs = [NSMutableSet new];
											 
											 NSMutableArray* divisions = nil;
											 if (account.corporationSheet.walletDivisions)
												 divisions = [account.corporationSheet.walletDivisions mutableCopy];
											 
											 NSMutableArray* allRows = [NSMutableArray new];
											 
											 if (corporate && balance) {
												 NSMutableArray* accounts = [NSMutableArray new];
												 float n = balance.accounts.count;
												 float p = 0.0;
												 for (EVEAccountBalanceItem* item in balance.accounts) {
													 EVECorpWalletTransactions* walletTransactions = [EVECorpWalletTransactions corpWalletTransactionsWithKeyID:account.apiKey.keyID
																																						  vCode:account.apiKey.vCode
																																					cachePolicy:cachePolicy
																																					characterID:account.characterID
																																				  beforeTransID:0
																																					 accountKey:item.accountKey
																																						  error:&error
																																				progressHandler:^(CGFloat progress, BOOL *stop) {
																																					task.progress = (p + progress) / n;
																																				}];
													 p += 1.0;
													 if (!walletTransactions)
														 return;
													 
													 NSMutableArray* rows = [NSMutableArray new];
													 for (EVECorpWalletTransactionsItem* transaction in walletTransactions.transactions) {
														 NCWalletTransactionsViewControllerDataRow* row = [NCWalletTransactionsViewControllerDataRow new];
														 row.transaction = transaction;
														 [locationsIDs addObject:@(transaction.stationID)];
														 [rows addObject:row];
														 [allRows addObject:row];
													 }
													 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"transaction.transactionDateTime" ascending:NO]]];
													 
													 NCWalletTransactionsViewControllerDataAccount* dataAccount = [NCWalletTransactionsViewControllerDataAccount new];
													 dataAccount.transactions = rows;
													 dataAccount.balance = item;
													 for (EVECorporationSheetDivisionItem* division in divisions) {
														 if (division.accountKey == item.accountKey) {
															 dataAccount.accountName = division.description;
															 [divisions removeObject:division];
															 break;
														 }
													 }
													 if (!dataAccount.accountName)
														 dataAccount.accountName = [NSString stringWithFormat:NSLocalizedString(@"Division %d", nil), item.accountKey - 1000 + 1];
													 [accounts addObject:dataAccount];
													 
												 }
												 data.accounts = accounts;
											 }
											 else if (!corporate) {
												 EVECharWalletTransactions* walletTransactions = [EVECharWalletTransactions charWalletTransactionsWithKeyID:account.apiKey.keyID
																																					  vCode:account.apiKey.vCode
																																				cachePolicy:cachePolicy
																																				characterID:account.characterID
																																			  beforeTransID:0
																																					  error:&error
																																			progressHandler:^(CGFloat progress, BOOL *stop) {
																																				if ([task isCancelled])
																																					*stop = YES;
																																				task.progress = progress;
																																			}];
												 if (!walletTransactions)
													 return;
												 
												 NSMutableArray* rows = [NSMutableArray new];
												 for (EVECharWalletTransactionsItem* transaction in walletTransactions.transactions) {
													 NCWalletTransactionsViewControllerDataRow* row = [NCWalletTransactionsViewControllerDataRow new];
													 row.transaction = transaction;
													 [locationsIDs addObject:@(transaction.stationID)];
													 [rows addObject:row];
													 [allRows addObject:row];
												 }
												 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"transaction.transactionDateTime" ascending:NO]]];

												 NCWalletTransactionsViewControllerDataAccount* dataAccount = [NCWalletTransactionsViewControllerDataAccount new];
												 dataAccount.transactions = rows;
												 if (balance.accounts.count > 0)
													 dataAccount.balance = balance.accounts[0];
												 data.accounts = @[dataAccount];
											 }
											 
											 
											 NSDictionary* locationNames = nil;
											 if (locationsIDs.count > 0)
												 locationNames = [[NCLocationsManager defaultManager] locationsNamesWithIDs:[locationsIDs allObjects]];
											 
											 NSMutableDictionary* typesDic = [NSMutableDictionary new];
											 for (NCWalletTransactionsViewControllerDataRow* row in allRows) {
												 int32_t typeID = [row.transaction typeID];
												 NCDBInvType* type = typesDic[@(typeID)];
												 if (!type) {
													 type = [NCDBInvType invTypeWithTypeID:typeID];
													 if (type)
														 typesDic[@(typeID)] = type;
												 }
												 
												 row.type = type;
												 row.location = locationNames[@([row.transaction stationID])];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:cacheExpireDate];
									 }
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[indexPath.section];
	NCWalletTransactionsViewControllerDataRow* row = account.transactions[indexPath.row];
	
	NCWalletTransactionsCell* cell = (NCWalletTransactionsCell*) tableViewCell;
	cell.object = row;
	
	if (row.type) {
		cell.typeImageView.image = row.type.icon ? row.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.titleLabel.text = row.type.typeName;
	}
	else {
		cell.typeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"74_14"] image] image];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), [row.transaction typeID]];
	}
	
	cell.dateLabel.text = [self.dateFormatter stringFromDate:[row.transaction transactionDateTime]];
	
	if (row.location.name)
		cell.locationLabel.text = row.location.name;
	else if (row.location.solarSystem)
		cell.locationLabel.text = row.location.solarSystem.solarSystemName;
	else
		cell.locationLabel.text = NSLocalizedString(@"Unknown location", nil);
	
	float price = [[row.transaction valueForKey:@"price"] floatValue];
	int32_t quantity = [[row.transaction valueForKey:@"quantity"] intValue];
	cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Price: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(price)]];
	cell.quantityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty: %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:quantity]];
	cell.amountLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(price * quantity)]];
	
	if ([[row.transaction transactionType] isEqualToString:@"sell"])
		cell.amountLabel.textColor = [UIColor greenColor];
	else
		cell.amountLabel.textColor = [UIColor redColor];
	
	if ([row.transaction isKindOfClass:[EVECharWalletTransactionsItem class]]) {
		NCAccount* account = [NCAccount currentAccount];
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", account.characterInfo.characterName, [row.transaction clientName]];
	}
	else
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", [row.transaction characterName], [row.transaction clientName]];
}

@end

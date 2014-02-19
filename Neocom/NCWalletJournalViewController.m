//
//  NCWalletJournalViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCWalletJournalViewController.h"
#import "EVEOnlineAPI.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCWalletJournalCell.h"

#define NCWalletJournalViewControllerItemsCount 200

@interface NCWalletJournalViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) id item;
@property (nonatomic, strong) EVERefTypesItem* refType;
@end


@interface NCWalletJournalViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, strong) NSString* accountName;
@end

@interface NCWalletJournalViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* accounts;
@end

@implementation NCWalletJournalViewControllerDataRow

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.item = [aDecoder decodeObjectForKey:@"item"];
		self.refType = [aDecoder decodeObjectForKey:@"refType"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.item)
		[aCoder encodeObject:self.item forKey:@"item"];
	if (self.refType)
		[aCoder encodeObject:self.refType forKey:@"refType"];
}

@end

@implementation NCWalletJournalViewControllerDataAccount

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.items = [aDecoder decodeObjectForKey:@"items"];
		self.accountName = [aDecoder decodeObjectForKey:@"accountName"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.items)
		[aCoder encodeObject:self.items forKey:@"items"];
	if (self.accountName)
		[aCoder encodeObject:self.accountName forKey:@"accountName"];
}

@end

@implementation NCWalletJournalViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.accounts = [aDecoder decodeObjectForKey:@"accounts"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.accounts)
		[aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end

@interface NCWalletJournalViewController ()
@property (nonatomic, strong) NCWalletJournalViewControllerData* searchResults;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@end

@implementation NCWalletJournalViewController

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return data.accounts.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[section];
	return account.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[section];
	return account.accountName;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[indexPath.section];
	NCWalletJournalViewControllerDataRow* row = account.items[indexPath.row];
	
	NCWalletJournalCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.object = row;
	
	cell.titleLabel.text = row.refType ? row.refType.refTypeName : [NSString stringWithFormat:NSLocalizedString(@"Unknown refTypeID %d", nil), [row.item refTypeID]];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:[row.item date]];

	
	cell.balanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Balance: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@([row.item balance])]];
	
	float amount = [row.item amount];
	float taxAmount = 0;
	if ([row.item isKindOfClass:[EVECharWalletTransactionsItem class]])
		taxAmount = [row.item taxAmount];
	
	//cell.amountLabel.text = [NSString shortStringWithFloat:amount + taxAmount unit:@"ISK"];
	cell.amountLabel.textColor = amount > 0 ? [UIColor greenColor] : [UIColor redColor];
	cell.amountLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(amount + taxAmount)]];
	
	if (taxAmount > 0)
		cell.taxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Tax: -%@ ISK (%d%%)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(taxAmount)], (int)(taxAmount / (taxAmount + amount) * 100)];
	else
		cell.taxLabel.text = nil;
	
	NSString* ownerName1 = [row.item ownerName1];
	NSString* ownerName2 = [row.item ownerName2];
	if (ownerName1.length > 0 && ownerName2.length > 0)
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", ownerName1, ownerName2];
	else
		cell.characterNameLabel.text = ownerName1;
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 87;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCWalletJournalViewControllerData* data = [NCWalletJournalViewControllerData new];
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
											 
											 EVERefTypes* refTypes = [EVERefTypes refTypesWithCachePolicy:cachePolicy error:nil progressHandler:nil];
											 NSMutableDictionary* refTypesDic = [NSMutableDictionary new];
											 for (EVERefTypesItem* item in refTypes.refTypes)
												 refTypesDic[@(item.refTypeID)] = item;
											 
											 NSMutableArray* divisions = nil;
											 if (account.corporationSheet.walletDivisions)
												 divisions = [account.corporationSheet.walletDivisions mutableCopy];
											 
											 if (corporate && balance) {
												 NSMutableArray* accounts = [NSMutableArray new];
												 float n = balance.accounts.count;
												 float p = 0.0;
												 for (EVEAccountBalanceItem* item in balance.accounts) {
													 EVECorpWalletJournal* walletJournal = [EVECorpWalletJournal corpWalletJournalWithKeyID:account.apiKey.keyID
																																	  vCode:account.apiKey.vCode
																																cachePolicy:cachePolicy
																																characterID:account.characterID
																																 accountKey:item.accountKey
																																	 fromID:0
																																   rowCount:NCWalletJournalViewControllerItemsCount
																																	  error:&error
																															progressHandler:^(CGFloat progress, BOOL *stop) {
																																task.progress = (p + progress) / n;
																															}];
													 p += 1.0;
													 if (!walletJournal)
														 return;
													 
													 NSMutableArray* rows = [NSMutableArray new];
													 for (EVECorpWalletJournalItem* item in walletJournal.corpWalletJournal) {
														 NCWalletJournalViewControllerDataRow* row = [NCWalletJournalViewControllerDataRow new];
														 row.item = item;
														 row.refType = refTypesDic[@(item.refTypeID)];
														 [rows addObject:row];
													 }
													 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item.date" ascending:NO]]];
													 
													 NCWalletJournalViewControllerDataAccount* dataAccount = [NCWalletJournalViewControllerDataAccount new];
													 dataAccount.items = rows;

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
												 EVECharWalletJournal* walletJournal = [EVECharWalletJournal charWalletJournalWithKeyID:account.apiKey.keyID
																																  vCode:account.apiKey.vCode
																															cachePolicy:cachePolicy
																															characterID:account.characterID
																																 fromID:0
																															   rowCount:NCWalletJournalViewControllerItemsCount
																																  error:&error
																														progressHandler:^(CGFloat progress, BOOL *stop) {
																															task.progress = progress;
																														}];
												 if (!walletJournal)
													 return;
												 
												 NSMutableArray* rows = [NSMutableArray new];
												 for (EVECharWalletJournalItem* item in walletJournal.charWalletJournal) {
													 NCWalletJournalViewControllerDataRow* row = [NCWalletJournalViewControllerDataRow new];
													 row.item = item;
													 row.refType = refTypesDic[@(item.refTypeID)];
													 [rows addObject:row];
												 }
												 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item.date" ascending:NO]]];

												 
												 NCWalletJournalViewControllerDataAccount* dataAccount = [NCWalletJournalViewControllerDataAccount new];
												 dataAccount.items = rows;
												 data.accounts = @[dataAccount];
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

@end

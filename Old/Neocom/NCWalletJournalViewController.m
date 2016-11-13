//
//  NCWalletJournalViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCWalletJournalViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCWalletJournalCell.h"

#define NCWalletJournalViewControllerItemsCount 200

@interface NCWalletJournalViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) EVEWalletJournalItem* item;
@property (nonatomic, strong) EVERefTypesItem* refType;
@end


@interface NCWalletJournalViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, strong) NSString* accountName;
@property (nonatomic, strong) EVEAccountBalanceItem* balance;
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
		self.balance = [aDecoder decodeObjectForKey:@"balance"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.items)
		[aCoder encodeObject:self.items forKey:@"items"];
	if (self.accountName)
		[aCoder encodeObject:self.accountName forKey:@"accountName"];
	if (self.balance)
		[aCoder encodeObject:self.balance forKey:@"balance"];
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
@property (nonatomic, strong) NCAccount* account;

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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	return data.accounts.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[section];
	return account.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[section];
	if (account.accountName)
		return [NSString stringWithFormat:@"%@: %@ ISK", account.accountName, [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
	else
		return [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCWalletJournalViewControllerData* data = cacheData;
	self.backgrountText = data.accounts.count > 0 ? nil : NSLocalizedString(@"No Results", nil);

	completionBlock();
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:4];
	
	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		NCWalletJournalViewControllerData* data = [NCWalletJournalViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		BOOL corporate = api.apiKey.corporate;
		
		
		dispatch_group_t finishDispatchGroup = dispatch_group_create();
		__block EVEAccountBalance* balance;
		NSMutableDictionary* refTypesDic = [NSMutableDictionary new];
		dispatch_group_enter(finishDispatchGroup);
		[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *result, NSError *error) {
			if (error)
				lastError = error;
			balance = result;
			@synchronized(progress) {
				progress.completedUnitCount++;
			}
			dispatch_group_leave(finishDispatchGroup);
		}];

		dispatch_group_enter(finishDispatchGroup);
		[api refTypesWithCompletionBlock:^(EVERefTypes *result, NSError *error) {
			if (error)
				lastError = error;
			
			for (EVERefTypesItem* item in result.refTypes)
				refTypesDic[@(item.refTypeID)] = item;

			@synchronized(progress) {
				progress.completedUnitCount++;
			}
			dispatch_group_leave(finishDispatchGroup);
		}];
		
		dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			@autoreleasepool {
				dispatch_group_t finishDispatchGroup = dispatch_group_create();
				NSMutableArray* accounts = [NSMutableArray new];

				if (corporate) {
					dispatch_group_enter(finishDispatchGroup);
					[account loadCorporationSheetWithCompletionBlock:^(EVECorporationSheet *corporationSheet, NSError *error) {
						if (error)
							lastError = error;
						
						NSMutableArray* divisions = [corporationSheet.divisions mutableCopy];
						
						[progress becomeCurrentWithPendingUnitCount:1];
						NSProgress* walletProgress = [NSProgress progressWithTotalUnitCount:balance.accounts.count];
						[progress resignCurrent];
						
						
						for (EVEAccountBalanceItem* item in balance.accounts) {
							dispatch_group_enter(finishDispatchGroup);
							[api corpWalletJournalWithAccountKey:item.accountKey
														  fromID:0
														rowCount:200
												 completionBlock:^(EVECorpWalletJournal *result, NSError *error)
							 {
								 if (error)
									 lastError = error;
								 
								 if (result) {
									 NSMutableArray* rows = [NSMutableArray new];
									 for (EVEWalletJournalItem* item in result.entries) {
										 NCWalletJournalViewControllerDataRow* row = [NCWalletJournalViewControllerDataRow new];
										 row.item = item;
										 row.refType = refTypesDic[@(item.refTypeID)];
										 [rows addObject:row];
									 }
									 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item.date" ascending:NO]]];
									 
									 NCWalletJournalViewControllerDataAccount* dataAccount = [NCWalletJournalViewControllerDataAccount new];
									 dataAccount.items = rows;
									 dataAccount.balance = item;
									 
									 for (EVECorporationSheetDivisionItem* division in divisions) {
										 if (division.accountKey == item.accountKey) {
											 dataAccount.accountName = division.divisionDescription;
											 [divisions removeObject:division];
											 break;
										 }
									 }
									 if (!dataAccount.accountName)
										 dataAccount.accountName = [NSString stringWithFormat:NSLocalizedString(@"Division %d", nil), item.accountKey - 1000 + 1];
									 
									 @synchronized(accounts) {
										 [accounts addObject:dataAccount];
									 }
								 }
								 
								 @synchronized(walletProgress) {
									 walletProgress.completedUnitCount++;
								 }
								 dispatch_group_leave(finishDispatchGroup);
							 }];
						}
						dispatch_group_leave(finishDispatchGroup);
					}];
				}
				else {
					dispatch_group_enter(finishDispatchGroup);
					[api charWalletJournalFromID:0
										rowCount:200
								 completionBlock:^(EVECharWalletJournal *result, NSError *error)
					{
						if (result) {
							NSMutableArray* rows = [NSMutableArray new];
							for (EVECharWalletJournalItem* item in result.transactions) {
								NCWalletJournalViewControllerDataRow* row = [NCWalletJournalViewControllerDataRow new];
								row.item = item;
								row.refType = refTypesDic[@(item.refTypeID)];
								[rows addObject:row];
							}
							[rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item.date" ascending:NO]]];
							
							NCWalletJournalViewControllerDataAccount* dataAccount = [NCWalletJournalViewControllerDataAccount new];
							dataAccount.items = rows;
							if (balance.accounts.count > 0)
								dataAccount.balance = balance.accounts[0];

							@synchronized(accounts) {
								[accounts addObject:dataAccount];
							}
						}
						dispatch_group_leave(finishDispatchGroup);

					}];
				}
				
				dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					@autoreleasepool {
						[accounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"balance.accountKey" ascending:YES]]];
						data.accounts = accounts;
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
							completionBlock(lastError);
							progress.completedUnitCount++;
						});
					}
				});
				
			}
		});

	}];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCWalletJournalViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletJournalViewControllerDataAccount* account = data.accounts[indexPath.section];
	NCWalletJournalViewControllerDataRow* row = account.items[indexPath.row];
	
	NCWalletJournalCell* cell = (NCWalletJournalCell*) tableViewCell;
	cell.object = row;
	
	cell.titleLabel.text = row.refType ? row.refType.refTypeName : [NSString stringWithFormat:NSLocalizedString(@"Unknown refTypeID %d", nil), row.item.refTypeID];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.item.date];
	
	
	cell.balanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Balance: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.item.balance)]];
	
	float amount = row.item.amount;
	float taxAmount = 0;
	if ([row.item isKindOfClass:[EVECharWalletJournalItem class]])
		taxAmount = [(EVECharWalletJournalItem*) row.item taxAmount];
	
	cell.amountLabel.textColor = amount > 0 ? [UIColor greenColor] : [UIColor redColor];
	cell.amountLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(amount + taxAmount)]];
	
	if (taxAmount > 0)
		cell.taxLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Tax: -%@ ISK (%d%%)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(taxAmount)], (int32_t)(taxAmount / (taxAmount + amount) * 100)];
	else
		cell.taxLabel.text = nil;
	
	NSString* ownerName1 = [row.item ownerName1];
	NSString* ownerName2 = [row.item ownerName2];
	if (ownerName1.length > 0 && ownerName2.length > 0)
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", ownerName1, ownerName2];
	else
		cell.characterNameLabel.text = ownerName1;
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), uuid];
		});
	}];
}

@end

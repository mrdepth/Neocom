//
//  NCWalletTransactionsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 18.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCWalletTransactionsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCLocationsManager.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCWalletTransactionsCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCWalletTransactionsViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) EVEWalletTransactionsItem* transaction;
@property (nonatomic, strong) NCLocationsManagerItem* location;
@property (nonatomic, strong) NSString* characterName;
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
		self.characterName = [aDecoder decodeObjectForKey:@"characterName"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.transaction)
		[aCoder encodeObject:self.transaction forKey:@"transaction"];
	if (self.location)
		[aCoder encodeObject:self.location forKey:@"location"];
	if (self.characterName)
		[aCoder encodeObject:self.characterName forKey:@"characterName"];
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
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;
@property (nonatomic, strong) NCAccount* account;

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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.unknownTypeIcon = 	[self.databaseManagedObjectContext eveIconWithIconFile:@"74_14"];
	self.types = [NSMutableDictionary new];
	self.solarSystems = [NSMutableDictionary new];
	self.account = [NCAccount currentAccount];
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
		NCDBInvType* type = self.types[@(row.transaction.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:row.transaction.typeID];
			if (type)
				self.types[@(row.transaction.typeID)] = type;
		}
		controller.typeID = [type objectID];
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCWalletTransactionsViewControllerDataRow* row = [sender object];
		NCDBInvType* type = self.types[@(row.transaction.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:row.transaction.typeID];
			if (type)
				self.types[@(row.transaction.typeID)] = type;
		}
		return type != nil;
	}
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	return data.accounts.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[section];
	return account.transactions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[section];
	if (account.accountName)
		return [NSString stringWithFormat:@"%@: %@ ISK", account.accountName, [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
	else
		return [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(account.balance.balance)]];
}


#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock progressBlock:(void (^)(float))progressBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:3];

	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		NCWalletTransactionsViewControllerData* data = [NCWalletTransactionsViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		BOOL corporate = api.apiKey.corporate;
		
		[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *balance, NSError *error) {
			progress.completedUnitCount++;
			if (error)
				lastError = error;

			NSMutableSet* locationsIDs = [NSMutableSet new];
			NSMutableArray* allRows = [NSMutableArray new];
			NSMutableArray* accounts = [NSMutableArray new];
			dispatch_group_t finishDispatchGroup = dispatch_group_create();

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
						[api corpWalletTransactionsWithAccountKey:item.accountKey
														   fromID:0
														 rowCount:200
												  completionBlock:^(EVECorpWalletTransactions *result, NSError *error)
							{
								if (error)
									lastError = error;

								if (result) {
									NSMutableArray* rows = [NSMutableArray new];
									for (EVECorpWalletTransactionsItem* transaction in result.transactions) {
										NCWalletTransactionsViewControllerDataRow* row = [NCWalletTransactionsViewControllerDataRow new];
										row.transaction = transaction;
										row.characterName = [NSString stringWithFormat:@"%@ -> %@", transaction.characterName, transaction.clientName];
															 
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
							} progressBlock:nil];
					}
					dispatch_group_leave(finishDispatchGroup);
				}];
			}
			else {
				dispatch_group_enter(finishDispatchGroup);
				[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
					if (error)
						lastError = error;

					[api charWalletTransactionsFromID:0
											 rowCount:200
									  completionBlock:^(EVECharWalletTransactions *result, NSError *error)
					 {
						 if (error)
							 lastError = error;

						 if (result) {
							 NSMutableArray* rows = [NSMutableArray new];
							 for (EVEWalletTransactionsItem* transaction in result.transactions) {
								 NCWalletTransactionsViewControllerDataRow* row = [NCWalletTransactionsViewControllerDataRow new];
								 row.transaction = transaction;
								 row.characterName = [NSString stringWithFormat:@"%@ -> %@", characterInfo.characterName, transaction.clientName];
								 
								 [locationsIDs addObject:@(transaction.stationID)];
								 [rows addObject:row];
								 [allRows addObject:row];
							 }
							 [rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"transaction.transactionDateTime" ascending:NO]]];
							 
							 NCWalletTransactionsViewControllerDataAccount* dataAccount = [NCWalletTransactionsViewControllerDataAccount new];
							 dataAccount.transactions = rows;
							 if (balance.accounts.count > 0)
								 dataAccount.balance = balance.accounts[0];
							 [accounts addObject:dataAccount];
						 }
						 @synchronized(progress) {
							 progress.completedUnitCount++;
						 }
						 dispatch_group_leave(finishDispatchGroup);
					 } progressBlock:nil];
				}];
			}
			
			dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					[accounts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"balance.accountKey" ascending:YES]]];
					data.accounts = accounts;
					
					if (locationsIDs.count > 0) {
						[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:[locationsIDs allObjects] completionBlock:^(NSDictionary *result) {
							for (NCWalletTransactionsViewControllerDataRow* row in allRows)
								row.location = result[@(row.transaction.stationID)];
							
							dispatch_async(dispatch_get_main_queue(), ^{
								[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
								completionBlock(lastError);
								progress.completedUnitCount++;
							});
						}];
					}
					else
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
							completionBlock(lastError);
							progress.completedUnitCount++;
						});
				}
			});
		} progressBlock:nil];
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
	NCWalletTransactionsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCWalletTransactionsViewControllerDataAccount* account = data.accounts[indexPath.section];
	NCWalletTransactionsViewControllerDataRow* row = account.transactions[indexPath.row];
	
	NCWalletTransactionsCell* cell = (NCWalletTransactionsCell*) tableViewCell;
	cell.object = row;
	
	NCDBInvType* type = self.types[@(row.transaction.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:row.transaction.typeID];
		if (type)
			self.types[@(row.transaction.typeID)] = type;
	}

	if (type) {
		cell.typeImageView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.titleLabel.text = type.typeName;
	}
	else {
		cell.typeImageView.image = self.unknownTypeIcon.image.image;
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), [row.transaction typeID]];
	}
	
	cell.dateLabel.text = [self.dateFormatter stringFromDate:[row.transaction transactionDateTime]];
	
	if (row.location.name)
		cell.locationLabel.text = row.location.name;
	else if (row.location.solarSystemID) {
		NCDBMapSolarSystem* solarSystem = self.solarSystems[@(row.location.solarSystemID)];
		if (!solarSystem) {
			solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:row.location.solarSystemID];
			if (solarSystem)
				self.solarSystems[@(row.location.solarSystemID)] = solarSystem;
		};
		cell.locationLabel.text = solarSystem.solarSystemName;
	}
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
	
/*	if ([row.transaction isKindOfClass:[EVECorpWalletTransactionsItem class]]) {
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", [row.transaction characterName], [row.transaction clientName]];
	}
	else {
		NCAccount* account = [NCAccount currentAccount];
		cell.characterNameLabel.text = [NSString stringWithFormat:@"%@ -> %@", account.characterInfo.characterName, [row.transaction clientName]];
	}*/
	cell.characterNameLabel.text = row.characterName;
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

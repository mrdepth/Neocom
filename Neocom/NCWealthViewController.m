//
//  NCWealthViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCWealthViewController.h"
#import "NCWealthCell.h"
#import "NCPriceManager.h"

@interface NCWealthViewControllerData : NSObject<NSCoding>
@property (nonatomic, assign) double account;
@property (nonatomic, assign) double assets;
@property (nonatomic, assign) double industry;
@property (nonatomic, assign) double market;
@property (nonatomic, assign) double contracts;
@end

@implementation NCWealthViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.account = [aDecoder decodeDoubleForKey:@"account"];
		self.assets = [aDecoder decodeDoubleForKey:@"assets"];
		self.industry = [aDecoder decodeDoubleForKey:@"industry"];
		self.market = [aDecoder decodeDoubleForKey:@"market"];
		self.contracts = [aDecoder decodeDoubleForKey:@"contracts"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeDouble:self.account forKey:@"account"];
	[aCoder encodeDouble:self.assets forKey:@"assets"];
	[aCoder encodeDouble:self.industry forKey:@"industry"];
	[aCoder encodeDouble:self.market forKey:@"market"];
	[aCoder encodeDouble:self.contracts forKey:@"contracts"];
}

@end

@interface NCWealthViewController ()
@property (nonatomic, strong) NCAccount* account;

- (NSNumberFormatter*) numberFormatterWithTitle:(NSString*) title value:(double) value multiplier:(double *) multiplier;

@end

@implementation NCWealthViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCWealthViewControllerData* data = self.cacheData;
	return data ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	completionBlock();
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:3];
	
	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		NCWealthViewControllerData* data = [NCWealthViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		
		[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *result, NSError *error) {
			double sum = 0;
			for (EVEAccountBalanceItem* account in result.accounts)
				sum += account.balance;
			data.account = sum;
			[self saveCacheData:data cacheDate:nil expireDate:nil];
			NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor greenColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Account", nil) value:sum]] animated:YES];

		} progressBlock:nil];
		[api assetListWithCompletionBlock:^(EVEAssetList *result, NSError *error) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				NSMutableDictionary* typeIDs = [NSMutableDictionary new];
				
				__weak __block void (^weakProcess)(EVEAssetListItem*) = nil;
				
				void (^process)(EVEAssetListItem*) = ^(EVEAssetListItem* asset) {
					typeIDs[@(asset.typeID)] = @([typeIDs[@(asset.typeID)] longLongValue] + asset.quantity);

					for (EVEAssetListItem* item in asset.contents)
						weakProcess(item);
				};
				weakProcess = process;
				
				for (EVEAssetListItem* asset in result.assets)
					process(asset);
				
				[[NCPriceManager sharedManager] requestPricesWithTypes:[typeIDs allKeys]
													   completionBlock:^(NSDictionary *prices) {
														   __block double sum = 0;
														   [typeIDs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
															   double price = [prices[key] doubleValue];
															   sum += price * [obj longLongValue];
														   }];
														   data.assets = sum;
														   dispatch_async(dispatch_get_main_queue(), ^{
															   [self saveCacheData:data cacheDate:nil expireDate:nil];
															   if (sum > 0) {
																   NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
																   [cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor cyanColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Assets", nil) value:sum]] animated:YES];
															   }
														   });
													   }];

				
			});
			[self saveCacheData:data cacheDate:nil expireDate:nil];
		} progressBlock:nil];
		[api industryJobsHistoryWithCompletionBlock:^(EVEIndustryJobsHistory *result, NSError *error) {
			[self saveCacheData:data cacheDate:nil expireDate:nil];
		} progressBlock:nil];
		[api marketOrdersWithOrderID:0 completionBlock:^(EVEMarketOrders *result, NSError *error) {
			[self saveCacheData:data cacheDate:nil expireDate:nil];
		} progressBlock:nil];
		[api contractsWithContractID:0 completionBlock:^(EVEContracts *result, NSError *error) {
			[self saveCacheData:data cacheDate:nil expireDate:nil];
		} progressBlock:nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
			completionBlock(lastError);
			progress.completedUnitCount++;
		});
	}];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"NCWealthCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCWealthViewControllerData* data = self.cacheData;
	NCWealthCell* cell = (NCWealthCell*) tableViewCell;
	[cell.pieChartView clear];
//	[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:100 color:[UIColor greenColor] numberFormatter:nil] animated:NO];
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

- (NSNumberFormatter*) numberFormatterWithTitle:(NSString*) title value:(double) value {
	NSNumberFormatter* formatter = [NSNumberFormatter new];
	NSString* abbreviation;
	if (value >= 1E12) {
		abbreviation = NSLocalizedString(@"T", nil);
		formatter.multiplier = @((double) 1E-12);
	}
	else if (value >= 1E9) {
		abbreviation = NSLocalizedString(@"B", nil);
		formatter.multiplier = @((double) 1E-9);
	}
	else if (value >= 1E6) {
		abbreviation = NSLocalizedString(@"M", nil);
		formatter.multiplier = @((double) 1E-6);
	}
	else if (value >= 1E3) {
		abbreviation = NSLocalizedString(@"k", nil);
		formatter.multiplier = @((double) 1E-3);
	}
	else
		abbreviation = @"";
	formatter.positiveFormat = [NSString stringWithFormat:NSLocalizedString(@"%@\n#,##0.00%@ ISK", nil), title, abbreviation];
	return formatter;
}

@end

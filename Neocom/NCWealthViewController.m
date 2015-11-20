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
#import "NSNumberFormatter+Neocom.h"

@interface NCWealthViewControllerData : NSObject<NSCoding>
@property (nonatomic, assign) double account;
@property (nonatomic, assign) double assets;
@property (nonatomic, assign) double industry;
@property (nonatomic, assign) double market;
@property (nonatomic, assign) double contracts;
@property (nonatomic, assign) double implants;
@end

@implementation NCWealthViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.account = [aDecoder decodeDoubleForKey:@"account"];
		self.assets = [aDecoder decodeDoubleForKey:@"assets"];
		self.industry = [aDecoder decodeDoubleForKey:@"industry"];
		self.market = [aDecoder decodeDoubleForKey:@"market"];
		self.contracts = [aDecoder decodeDoubleForKey:@"contracts"];
		self.implants = [aDecoder decodeDoubleForKey:@"implants"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeDouble:self.account forKey:@"account"];
	[aCoder encodeDouble:self.assets forKey:@"assets"];
	[aCoder encodeDouble:self.industry forKey:@"industry"];
	[aCoder encodeDouble:self.market forKey:@"market"];
	[aCoder encodeDouble:self.contracts forKey:@"contracts"];
	[aCoder encodeDouble:self.implants forKey:@"implants"];
}

@end

@interface NCWealthViewController ()
@property (nonatomic, strong) NCAccount* account;

- (NSNumberFormatter*) numberFormatterWithTitle:(NSString*) title value:(double) value;

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
	return 8;
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
	__block BOOL clear = YES;
	
	[account.managedObjectContext performBlock:^{
		int32_t characterID = account.characterID;
		__block NSError* lastError = nil;
		NCWealthViewControllerData* data = [NCWealthViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		BOOL corporate = api.apiKey.corporate;
		
		[api accountBalanceWithCompletionBlock:^(EVEAccountBalance *result, NSError *error) {
			double sum = 0;
			for (EVEAccountBalanceItem* account in result.accounts)
				sum += account.balance;
			data.account = sum;
			[self saveCacheData:data cacheDate:nil expireDate:nil];
			NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
			if (clear) {
				[cell.pieChartView clear];
				clear = NO;
			}
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor greenColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Account", nil) value:sum]] animated:YES];
			[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

		} progressBlock:nil];
		[api assetListWithCompletionBlock:^(EVEAssetList *result, NSError *error) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
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
					
					if (typeIDs.count > 0) {
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
																		   if (clear) {
																			   [cell.pieChartView clear];
																			   clear = NO;
																		   }
																		   [cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor cyanColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Assets", nil) value:sum]] animated:YES];
																	   }
																	   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
																   });
															   }];
					}
					else {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:nil expireDate:nil];
							[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
						});
					}
				}
			});
		} progressBlock:nil];
		[api industryJobsHistoryWithCompletionBlock:^(EVEIndustryJobsHistory *result, NSError *error) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					NSMutableDictionary* typeIDs = [NSMutableDictionary new];
					
					for (EVEIndustryJobsItem* job in result.jobs) {
						if (job.activityID == 1) {//manufacturing
							if (job.status == EVEIndustryJobStatusActive || job.status == EVEIndustryJobStatusPaused || job.status == EVEIndustryJobStatusPaused)
								typeIDs[@(job.productTypeID)] = @([typeIDs[@(job.productTypeID)] longLongValue] + job.runs);
						}
/*						else {
							if (job.productTypeID)
								typeIDs[@(job.productTypeID)] = @([typeIDs[@(job.productTypeID)] longLongValue] + 1);
							else
								typeIDs[@(job.blueprintTypeID)] = @([typeIDs[@(job.blueprintTypeID)] longLongValue] + 1);
						}*/
					}
					
					
					if (typeIDs.count > 0) {
						[[NCPriceManager sharedManager] requestPricesWithTypes:[typeIDs allKeys]
															   completionBlock:^(NSDictionary *prices) {
																   __block double sum = 0;
																   [typeIDs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
																	   double price = [prices[key] doubleValue];
																	   sum += price * [obj longLongValue];
																   }];
																   data.industry = sum;
																   dispatch_async(dispatch_get_main_queue(), ^{
																	   [self saveCacheData:data cacheDate:nil expireDate:nil];
																	   if (sum > 0) {
																		   NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
																		   if (clear) {
																			   [cell.pieChartView clear];
																			   clear = NO;
																		   }
																		   [cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor redColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Industry", nil) value:sum]] animated:YES];
																	   }
																	   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
																   });
															   }];
					}
					else {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:nil expireDate:nil];
							[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
						});
					}
				}
			});
		} progressBlock:nil];
		[api marketOrdersWithOrderID:0 completionBlock:^(EVEMarketOrders *result, NSError *error) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					__block double sum = 0;
					NSMutableDictionary* typeIDs = [NSMutableDictionary new];
					for (EVEMarketOrdersItem* marketOrder in result.orders) {
						if (marketOrder.orderState == EVEOrderStateOpen) {
							if (marketOrder.bid)
								sum += marketOrder.price * marketOrder.volRemaining;
							else
								typeIDs[@(marketOrder.typeID)] = @([typeIDs[@(marketOrder.typeID)] longLongValue] + marketOrder.volRemaining);
						}
					}
					
					void (^finalize)() = ^{
						data.market = sum;
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:nil expireDate:nil];
							if (sum > 0) {
								NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
								if (clear) {
									[cell.pieChartView clear];
									clear = NO;
								}
								[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor yellowColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Market", nil) value:sum]] animated:YES];
							}
							[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
						});
					};
					
					if (typeIDs.count > 0) {
						[[NCPriceManager sharedManager] requestPricesWithTypes:[typeIDs allKeys]
															   completionBlock:^(NSDictionary *prices) {
																   [typeIDs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
																	   double price = [prices[key] doubleValue];
																	   sum += price * [obj longLongValue];
																   }];
																   finalize();
															   }];
					}
					else
						finalize();
				}
			});
		} progressBlock:nil];
		[api contractsWithContractID:0 completionBlock:^(EVEContracts *result, NSError *error) {
			double sum = 0;
			for (EVEContractsItem* contract in result.contractList) {
				if (contract.issuerID == characterID && (contract.status == EVEContractStatusInProgress || contract.status == EVEContractStatusOutstanding))
					sum += contract.price;
			}
			data.contracts = sum;
			[self saveCacheData:data cacheDate:nil expireDate:nil];
			if (sum > 0) {
				NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
				if (clear) {
					[cell.pieChartView clear];
					clear = NO;
				}
				[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor orangeColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Contracts", nil) value:sum]] animated:YES];
			}
			[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		} progressBlock:nil];
		
		
		if (!corporate) {
			NSMutableDictionary* typeIDs = [NSMutableDictionary new];
			[api characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
				for (EVECharacterSheetImplant* implant in result.implants)
					typeIDs[@(implant.typeID)] = @([typeIDs[@(implant.typeID)] longLongValue] + 1);
				for (EVECharacterSheetJumpCloneImplant* implant in result.jumpCloneImplants)
					typeIDs[@(implant.typeID)] = @([typeIDs[@(implant.typeID)] longLongValue] + 1);
				
				if (typeIDs.count > 0) {
					[[NCPriceManager sharedManager] requestPricesWithTypes:[typeIDs allKeys]
														   completionBlock:^(NSDictionary *prices) {
															   __block double sum = 0;
															   [typeIDs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
																   double price = [prices[key] doubleValue];
																   sum += price * [obj longLongValue];
															   }];
															   data.implants = sum;
															   dispatch_async(dispatch_get_main_queue(), ^{
																   [self saveCacheData:data cacheDate:nil expireDate:nil];
																   if (sum > 0) {
																	   NCWealthCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
																	   if (clear) {
																		   [cell.pieChartView clear];
																		   clear = NO;
																	   }
																	   [cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:sum color:[UIColor colorWithWhite:0.9 alpha:1] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Implants", nil) value:sum]] animated:YES];
																   }
																   [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
															   });
														   }];
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self saveCacheData:data cacheDate:nil expireDate:nil];
						[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
					});
				}

				
			} progressBlock:nil];
		}
		
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
	return indexPath.row == 0 ? @"NCWealthCell" : @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCWealthViewControllerData* data = self.cacheData;
	if (indexPath.row == 0) {
		NCWealthCell* cell = (NCWealthCell*) tableViewCell;
		[cell.pieChartView clear];
		[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.account color:[UIColor greenColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Account", nil) value:data.account]] animated:YES];
		if (data.assets > 0)
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.assets color:[UIColor cyanColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Assets", nil) value:data.assets]] animated:YES];
		if (data.industry > 0)
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.industry color:[UIColor redColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Industry", nil) value:data.industry]] animated:YES];
		if (data.market > 0)
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.market color:[UIColor yellowColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Market", nil) value:data.market]] animated:YES];
		if (data.contracts > 0)
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.contracts color:[UIColor orangeColor] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Contracts", nil) value:data.contracts]] animated:YES];
		if (data.implants > 0)
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:data.implants color:[UIColor colorWithWhite:0.9 alpha:1] numberFormatter:[self numberFormatterWithTitle:NSLocalizedString(@"Implants", nil) value:data.implants]] animated:YES];
	}
	else {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		if (indexPath.row == 1) {
			cell.titleLabel.text = NSLocalizedString(@"Account", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.account)]];
		}
		else if (indexPath.row == 2) {
			cell.titleLabel.text = NSLocalizedString(@"Assets", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.assets)]];
		}
		else if (indexPath.row == 3) {
			cell.titleLabel.text = NSLocalizedString(@"Industry", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.industry)]];
		}
		else if (indexPath.row == 4) {
			cell.titleLabel.text = NSLocalizedString(@"Market", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.market)]];
		}
		else if (indexPath.row == 5) {
			cell.titleLabel.text = NSLocalizedString(@"Contracts", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.contracts)]];
		}
		else if (indexPath.row == 6) {
			cell.titleLabel.text = NSLocalizedString(@"Implants", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.implants)]];
		}
		else if (indexPath.row == 7) {
			cell.titleLabel.text = NSLocalizedString(@"Total", nil);
			cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(data.account + data.assets + data.industry + data.market + data.contracts + data.implants)]];
		}
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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

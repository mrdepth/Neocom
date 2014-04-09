//
//  NCContractsDetailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCContractsDetailsViewController.h"
#import "NCTableViewCell.h"
#import "EVEContractsItem+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCContractsDetailsViewControllerDataBid : NSObject<NSCoding>
@property (nonatomic, strong) EVEContractBidsItem* bid;
@property (nonatomic, strong) NSString* bidderName;

@end

@interface NCContractsDetailsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong) EVEContractItems* items;
@property (nonatomic, strong) NSArray* bids;
@end

@interface NCContractsDetailsViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* description;

- (id) initWithTitle:(NSString*) title description:(NSString*) description;
@end

@implementation NCContractsDetailsViewControllerDataBid

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.bid = [aDecoder decodeObjectForKey:@"bid"];
		self.bidderName = [aDecoder decodeObjectForKey:@"bidderName"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.bid)
		[aCoder encodeObject:self.bid forKey:@"bid"];
	if (self.bidderName)
		[aCoder encodeObject:self.bidderName forKey:@"bidderName"];
}

@end

@implementation NCContractsDetailsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.items = [aDecoder decodeObjectForKey:@"items"];
		self.bids = [aDecoder decodeObjectForKey:@"bids"];
		self.rows = [aDecoder decodeObjectForKey:@"rows"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.items)
		[aCoder encodeObject:self.items forKey:@"items"];
	if (self.bids)
		[aCoder encodeObject:self.bids forKey:@"bids"];
	if (self.rows)
		[aCoder encodeObject:self.rows forKey:@"rows"];
}

@end

@implementation NCContractsDetailsViewControllerDataRow

- (id) initWithTitle:(NSString*) title description:(NSString*) description {
	if (self = [super init]) {
		self.title = title;
		self.description = description;
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.description = [aDecoder decodeObjectForKey:@"description"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.title)
		[aCoder encodeObject:self.title forKey:@"title"];
	if (self.description)
		[aCoder encodeObject:self.description forKey:@"description"];
}

@end

@interface NCContractsDetailsViewController ()
@property (nonatomic, strong) NCCacheRecord* contractBidsCacheRecord;
@property (nonatomic, strong) EVEContractBids* contractBids;
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSMutableDictionary* typesDic;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@end

@implementation NCContractsDetailsViewController

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
	
	self.account = [NCAccount currentAccount];
	self.typesDic = [NSMutableDictionary new];
	// Do any additional setup after loading the view.
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
		
		controller.type = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCContractsDetailsViewControllerData* data = self.data;
	if (section == 0)
		return data.rows.count;
	else if (section == 1)
		return data.items.itemList.count;
	else
		return data.bids.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewCell* cell = nil;
	if (indexPath.section == 1)
		cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
	else
		cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

	NCContractsDetailsViewControllerData* data = self.data;

	if (indexPath.section == 0) {
		NCContractsDetailsViewControllerDataRow* row = data.rows[indexPath.row];
		cell.titleLabel.text = row.title;
		cell.subtitleLabel.text = row.description;
	}
	else if (indexPath.section == 1) {
		EVEContractItemsItem* item = data.items.itemList[indexPath.row];
		EVEDBInvType* type = self.typesDic[@(item.typeID)];
		if (!type) {
			type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
			if (type)
				self.typesDic[@(item.typeID)] = type;
		}
		
		cell.object = type;
		if (type) {
			cell.titleLabel.text = type.typeName;
			cell.iconView.image = [UIImage imageNamed:type.typeSmallImageName];
		}
		else {
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown Type %d", nil), item.typeID];
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		}
		cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Quantity: %@", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:item.quantity]];
	}
	else {
		NCContractsDetailsViewControllerDataBid* bid = data.bids[indexPath.row];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:bid.bid.amount]];
		cell.subtitleLabel.text = bid.bidderName;
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return [NSString stringWithFormat:@"%@.%d", [super recordID], self.contract.contractID];
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	if (!self.account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCContractsDetailsViewControllerData* data = [NCContractsDetailsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BOOL corporate = self.account.accountType == NCAccountTypeCorporate;
											 
											 EVEContractItems* contractItems = [EVEContractItems contractItemsWithKeyID:self.account.apiKey.keyID
																												  vCode:self.account.apiKey.vCode
																											cachePolicy:cachePolicy
																											characterID:self.account.characterID
																											 contractID:self.contract.contractID
																											  corporate:corporate
																												  error:&error
																										progressHandler:^(CGFloat progress, BOOL *stop) {
																											task.progress = progress;
																										}];
											 
											 NSMutableArray* bids = [NSMutableArray new];
											 NSMutableSet* characterIDs = [NSMutableSet new];
											 for (EVEContractBidsItem* bid in self.contractBids.bidList) {
												 if (bid.contractID == self.contract.contractID) {
													 NCContractsDetailsViewControllerDataBid* dataBid = [NCContractsDetailsViewControllerDataBid new];
													 dataBid.bid = bid;
													 [characterIDs addObject:@(bid.bidderID)];
													 [bids addObject:dataBid];
												 }
											 }
											 
											 EVECharacterName* characterName = nil;
											 if (characterIDs.count > 0)
												 characterName = [EVECharacterName characterNameWithIDs:[characterIDs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)]]]
																							cachePolicy:NSURLRequestUseProtocolCachePolicy
																								  error:nil
																						progressHandler:nil];
											 
											 for (NCContractsDetailsViewControllerDataBid* dataBid in bids) {
												 dataBid.bidderName = characterName.characters[@(dataBid.bid.bidderID)];
											 }
											 
											 NSMutableArray *rows = [NSMutableArray array];
											 
											 if (self.contract.title.length > 0)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Title", nil)
																													description:self.contract.title]];
												 
											 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Status", nil)
																												description:[self.contract localizedStatusString]]];
											 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Type", nil)
																												description:[self.contract localizedTypeString]]];

											 
											 if (self.contract.startStation)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Start Station", nil)
																													description:self.contract.startStation.name]];
											 if (self.contract.endStation)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"End Station", nil)
																													description:self.contract.endStation.name]];
											 if (self.contract.dateIssued)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Issued", nil)
																													description:[self.dateFormatter stringFromDate:self.contract.dateIssued]]];

											 if (self.contract.dateAccepted)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Accepted", nil)
																													description:[self.dateFormatter stringFromDate:self.contract.dateAccepted]]];
											 
											 if (self.contract.dateCompleted)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Completed", nil)
																													description:[self.dateFormatter stringFromDate:self.contract.dateCompleted]]];

											 if (self.contract.dateExpired)
												 [rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Expired", nil)
																													description:[self.dateFormatter stringFromDate:self.contract.dateExpired]]];

											 data.items = contractItems;
											 data.bids = bids;
											 data.rows = rows;
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

#pragma mark - Private

- (NCCacheRecord*) contractBidsCacheRecord {
	@synchronized(self) {
		if (!_contractBidsCacheRecord) {
			[[[NCCache sharedCache] managedObjectContext] performBlockAndWait:^{
				_contractBidsCacheRecord = [NCCacheRecord cacheRecordWithRecordID:[NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), self.account.uuid]];
			}];
		}
		return _contractBidsCacheRecord;
	}
}

- (EVEContractBids*) contractBids {
	@synchronized(self) {
		if (!_contractBids) {
			_contractBids = self.contractBidsCacheRecord.data.data;
		
			if (!_contractBids || [self.contractBidsCacheRecord.expireDate compare:[NSDate date]] == NSOrderedAscending) {
				EVEContractBids* contractBids = [EVEContractBids contractBidsWithKeyID:self.account.apiKey.keyID
																				 vCode:self.account.apiKey.vCode
																		   cachePolicy:NSURLRequestUseProtocolCachePolicy
																		   characterID:self.account.characterID
																			 corporate:self.account.accountType == NCAccountTypeCorporate
																				 error:nil
																	   progressHandler:nil];
				if (contractBids) {
					_contractBids = contractBids;
					NCCache* cache = [NCCache sharedCache];
					[cache.managedObjectContext performBlockAndWait:^{
						self.cacheRecord.data.data = contractBids;
						self.cacheRecord.date = contractBids.cacheDate;
						self.cacheRecord.expireDate = contractBids.cacheExpireDate;
						[cache saveContext];
					}];

				}
			}
		}
		return _contractBids;
	}
}

@end

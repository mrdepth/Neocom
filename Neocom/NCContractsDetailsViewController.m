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
@property (nonatomic, strong) NSArray* items;
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
@synthesize description = _description;

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
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;

- (void) loadContractBidsWithCompletionBlock:(void(^)(EVEContractBids* contractBids)) completionBlock;
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
	
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.unknownTypeIcon = 	[self.databaseManagedObjectContext eveIconWithIconFile:@"74_14"];
	self.types = [NSMutableDictionary new];

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
		
		controller.typeID = [[sender object] objectID];
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"])
		return [sender object] != nil;
	else
		return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCContractsDetailsViewControllerData* data = self.cacheData;
	if (section == 0)
		return data.rows.count;
	else if (section == 1)
		return data.items.count;
	else
		return data.bids.count;
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock progressBlock:(void (^)(float))progressBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:4];
	
	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		NCContractsDetailsViewControllerData* data = [NCContractsDetailsViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		
		dispatch_group_t finishDispatchGroup = dispatch_group_create();
		
		dispatch_group_enter(finishDispatchGroup);
		__block EVEContractItems* contractItems;
		[api contractItemsWithContractID:self.contract.contractID completionBlock:^(EVEContractItems *result, NSError *error) {
			if (error)
				lastError = error;
			contractItems = result;
			@synchronized(progress) {
				progress.completedUnitCount++;
			}
			dispatch_group_leave(finishDispatchGroup);
		} progressBlock:nil];
		
		[self loadContractBidsWithCompletionBlock:^(EVEContractBids *contractBids) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				@autoreleasepool {
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
					
					NSMutableArray* bids = [NSMutableArray new];
					NSMutableSet* characterIDs = [NSMutableSet new];
					for (EVEContractBidsItem* bid in contractBids.bidList) {
						if (bid.contractID == self.contract.contractID) {
							NCContractsDetailsViewControllerDataBid* dataBid = [NCContractsDetailsViewControllerDataBid new];
							dataBid.bid = bid;
							[characterIDs addObject:@(bid.bidderID)];
							[bids addObject:dataBid];
						}
					}
					
					dispatch_group_t finishDispatchGroup = dispatch_group_create();
					__block NSDictionary* characterName;
					if (characterIDs.count > 0) {
						dispatch_group_enter(finishDispatchGroup);
						[api characterNameWithIDs:[characterIDs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)]]]
								  completionBlock:^(EVECharacterName *result, NSError *error) {
									  NSMutableDictionary* dic = [NSMutableDictionary new];
									  for (EVECharacterIDItem* item in result.characters)
										  dic[@(item.characterID)] = item.name;
									  characterName = dic;
									  dispatch_group_leave(finishDispatchGroup);
									  @synchronized(progress) {
										  progress.completedUnitCount++;
									  }
								  } progressBlock:nil];
					}
					else
						@synchronized(progress) {
							progress.completedUnitCount++;
						}
					
					dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
						@autoreleasepool {
							for (NCContractsDetailsViewControllerDataBid* dataBid in bids)
								dataBid.bidderName = characterName[@(dataBid.bid.bidderID)];
							
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
							
							if (self.contract.price > 0)
								[rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Price", nil)
																								   description:[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.contract.price)]]]];
							if (self.contract.buyout > 0)
								[rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Buyout", nil)
																								   description:[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.contract.buyout)]]]];
							if (self.contract.reward > 0)
								[rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Reward", nil)
																								   description:[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.contract.reward)]]]];
							if (self.contract.collateral > 0)
								[rows addObject:[[NCContractsDetailsViewControllerDataRow alloc] initWithTitle:NSLocalizedString(@"Collateral", nil)
																								   description:[NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.contract.collateral)]]]];
							
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
							data.items = [contractItems.itemList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"included" ascending:NO]]];
							data.bids = bids;
							data.rows = rows;
							
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
	}];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1)
		return @"TypeCell";
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;

	NCContractsDetailsViewControllerData* data = self.cacheData;
	
	if (indexPath.section == 0) {
		NCContractsDetailsViewControllerDataRow* row = data.rows[indexPath.row];
		cell.titleLabel.text = row.title;
		cell.subtitleLabel.text = row.description;
	}
	else if (indexPath.section == 1) {
		EVEContractItemsItem* item = data.items[indexPath.row];
		NCDBInvType* type = self.types[@(item.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:item.typeID];
			if (type)
				self.types[@(item.typeID)] = type;
		}
		
		cell.object = type;
		if (type) {
			cell.titleLabel.text = type.typeName;
			cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		}
		else {
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown Type %d", nil), item.typeID];
			cell.iconView.image = self.unknownTypeIcon.image.image;
		}
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%@: %@", item.included ? NSLocalizedString(@"Quantity", nil) : NSLocalizedString(@"Required", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:item.quantity]];
	}
	else {
		NCContractsDetailsViewControllerDataBid* bid = data.bids[indexPath.row];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:bid.bid.amount]];
		cell.subtitleLabel.text = bid.bidderName;
	}
}

#pragma mark - Private

- (void) setAccount:(NCAccount *)account {
	_account = account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.cacheRecordID = [NSString stringWithFormat:@"%@.%@.%qi", NSStringFromClass(self.class), uuid, self.contract.contractID];
		});
	}];
}

- (void) loadContractBidsWithCompletionBlock:(void (^)(EVEContractBids* contractBids))completionBlock {
	NCAccount* account = self.account;
	[account.managedObjectContext performBlock:^{
		NSString* uuid = account.uuid;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:self.account.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy];
		
		[self.cacheManagedObjectContext performBlock:^{
			NSString* cacheRecordID = [NSString stringWithFormat:@"EVEContractBids.%@", uuid];
			NCCacheRecord* cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:cacheRecordID];
			__block EVEContractBids* contractBids = cacheRecord.data.data;
			if (!contractBids || [cacheRecord isExpired]) {
				[api contractBidsWithCompletionBlock:^(EVEContractBids *result, NSError *error) {
					if (result) {
						contractBids = result;
						[self.cacheManagedObjectContext performBlock:^{
							cacheRecord.data.data = result;
							cacheRecord.date = result.eveapi.cacheDate;
							cacheRecord.expireDate = result.eveapi.cachedUntil;
						}];
					}
					completionBlock(contractBids);
				} progressBlock:nil];
			}
			else {
				completionBlock(contractBids);
			}
		}];
	}];
}

@end

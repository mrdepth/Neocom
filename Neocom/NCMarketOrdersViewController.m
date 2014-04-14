//
//  NCMarketOrdersViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMarketOrdersViewController.h"
#import "EVEOnlineAPI.h"
#import "NCLocationsManager.h"
#import "NCMarketOrdersCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSDate+Neocom.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCMarketOrdersViewControllerDataRow : NSObject<NSCoding>
@property (nonatomic, strong) EVEMarketOrdersItem* marketOrder;
@property (nonatomic, strong) NCLocationsManagerItem* location;
@property (nonatomic, strong) NSString* characterName;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) NSDate* expireDate;
@end

@interface NCMarketOrdersViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* openOrders;
@property (nonatomic, strong) NSArray* closedOrders;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end

@implementation NCMarketOrdersViewControllerDataRow

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.marketOrder = [aDecoder decodeObjectForKey:@"marketOrder"];
		self.location = [aDecoder decodeObjectForKey:@"location"];
		self.characterName = [aDecoder decodeObjectForKey:@"characterName"];
		
		self.expireDate = [self.marketOrder.issued dateByAddingTimeInterval:self.marketOrder.duration * 24 * 3600];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.marketOrder)
		[aCoder encodeObject:self.marketOrder forKey:@"marketOrder"];
	if (self.location)
		[aCoder encodeObject:self.location forKey:@"location"];
	if (self.characterName)
		[aCoder encodeObject:self.location forKey:@"characterName"];
}

@end

@implementation NCMarketOrdersViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.openOrders = [aDecoder decodeObjectForKey:@"openOrders"];
		self.closedOrders = [aDecoder decodeObjectForKey:@"closedOrders"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		NSMutableDictionary* typesDic = [NSMutableDictionary new];
		if (!self.openOrders)
			self.openOrders = @[];
		if (!self.closedOrders)
			self.closedOrders = @[];

		for (NSArray* array in @[self.openOrders, self.closedOrders]) {
			for (NCMarketOrdersViewControllerDataRow* row in array) {
				EVEDBInvType* type = typesDic[@(row.marketOrder.typeID)];
				if (!type) {
					type = [EVEDBInvType invTypeWithTypeID:row.marketOrder.typeID error:nil];
					if (type)
						typesDic[@(row.marketOrder.typeID)] = type;
				}
				row.type = type;
			}
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.openOrders)
		[aCoder encodeObject:self.openOrders forKey:@"openOrders"];
	if (self.closedOrders)
		[aCoder encodeObject:self.closedOrders forKey:@"closedOrders"];
	if (self.currentTime)
		[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	if (self.cacheDate)
		[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];
}

@end

@interface NCMarketOrdersViewController ()
@property (nonatomic, strong) NCMarketOrdersViewControllerData* searchResults;
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@end

@implementation NCMarketOrdersViewController

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
		
		NCMarketOrdersViewControllerDataRow* row = [sender object];
		controller.type = row.type;
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCMarketOrdersViewControllerDataRow* row = [sender object];
		return row.type != nil;
	}
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return data.openOrders.count + data.closedOrders.count > 0 ? 2 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return section == 0 ? data.openOrders.count : data.closedOrders.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	NCMarketOrdersViewControllerDataRow* row = indexPath.section == 0 ? data.openOrders[indexPath.row] : data.closedOrders[indexPath.row];
	
	NCMarketOrdersCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.object = row;
	
	if (row.type) {
		cell.typeImageView.image = [UIImage imageNamed:[row.type typeSmallImageName]];
		cell.titleLabel.text = row.type.typeName;
	}
	else {
		cell.typeImageView.image = [UIImage imageNamed:@"Icons/icon74_14.png"];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.marketOrder.typeID];
	}
	
	NSString* state = nil;
	UIColor* stateColor;
	switch (row.marketOrder.orderState) {
		case EVEOrderStateOpen:
			state = NSLocalizedString(@"Open", nil);
			stateColor = [UIColor greenColor];
			break;
		case EVEOrderStateCancelled:
			state = NSLocalizedString(@"Cancelled", nil);
			stateColor = [UIColor redColor];
			break;
		case EVEOrderStateCharacterDeleted:
			state = NSLocalizedString(@"Deleted", nil);
			stateColor = [UIColor redColor];
			break;
		case EVEOrderStateClosed:
			state = NSLocalizedString(@"Closed", nil);
			stateColor = [UIColor redColor];
			break;
		case EVEOrderStateExpired:
			if (row.marketOrder.duration > 1) {
				state = NSLocalizedString(@"Expired", nil);
				stateColor = [UIColor redColor];
			}
			else {
				state = NSLocalizedString(@"Fulfilled", nil);
				stateColor = [UIColor greenColor];
			}
			break;
		case EVEOrderStatePending:
			state = NSLocalizedString(@"Pending", nil);
			stateColor = [UIColor yellowColor];
			break;
		default:
			break;
	}
	
	cell.stateLabel.text = state;
	cell.stateLabel.textColor = stateColor;
	
	NSTimeInterval expireInTime = [row.expireDate timeIntervalSinceDate:self.currentDate];
	
	if (expireInTime > 0)
		cell.expireLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Expired in %@", nil), [NSString stringWithTimeLeft:expireInTime componentsLimit:2]];
	else
		cell.expireLabel.text = NSLocalizedString(@"Expired", nil);

	if (row.location.name)
		cell.locationLabel.text = row.location.name;
	else if (row.location.solarSystem)
		cell.locationLabel.text = row.location.solarSystem.solarSystemName;
	else
		cell.locationLabel.text = NSLocalizedString(@"Unknown location", nil);
	
	cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Price: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.marketOrder.price)]];
	cell.quantityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty: %@ / %@", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:row.marketOrder.volEntered],
							   [NSNumberFormatter neocomLocalizedStringFromInteger:row.marketOrder.volRemaining]];
	
	if (row.characterName)
		cell.issuedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Issued %@ by %@", nil), [self.dateFormatter stringFromDate:row.marketOrder.issued], row.characterName];
	else
		cell.issuedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Issued %@", nil), [self.dateFormatter stringFromDate:row.marketOrder.issued]];

	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 101;
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

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCMarketOrdersViewControllerData* data = [NCMarketOrdersViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVEMarketOrders* marketOrders = [EVEMarketOrders marketOrdersWithKeyID:account.apiKey.keyID
																											  vCode:account.apiKey.vCode
																										cachePolicy:cachePolicy
																										characterID:account.characterID
																										  corporate:account.accountType == NCAccountTypeCorporate
																											  error:&error
																									progressHandler:^(CGFloat progress, BOOL *stop) {
																										task.progress = progress;
																										if ([task isCancelled])
																											*stop = YES;
																									}];
											 cacheExpireDate = marketOrders.cacheExpireDate;

											 if ([task isCancelled] || !marketOrders)
												 return;
											 
											 NSMutableDictionary* typesDic = [NSMutableDictionary new];
											 NSMutableSet* locationsIDs = [NSMutableSet new];
											 NSMutableSet* characterIDs = [NSMutableSet new];
											 
											 NSMutableArray* rows = [NSMutableArray new];
											 NSMutableArray* openOrders = [NSMutableArray new];
											 NSMutableArray* closedOrders = [NSMutableArray new];
											 for (EVEMarketOrdersItem* order in marketOrders.orders) {
												 if (order.duration == 0) //Market operations
													 continue;
												 
												 NCMarketOrdersViewControllerDataRow* row = [NCMarketOrdersViewControllerDataRow new];
												 row.marketOrder = order;
												 [locationsIDs addObject:@(order.stationID)];
												 [characterIDs addObject:@(order.charID)];
												 
												 EVEDBInvType* type = typesDic[@(order.typeID)];
												 if (!type) {
													 type = [EVEDBInvType invTypeWithTypeID:order.typeID error:nil];
													 if (type)
														 typesDic[@(order.typeID)] = type;
												 }
												 row.type = type;
												 [rows addObject:row];
												 
												 if (order.orderState == EVEOrderStateOpen)
													 [openOrders addObject:row];
												 else
													 [closedOrders addObject:row];
												 
												 row.expireDate = [order.issued dateByAddingTimeInterval:order.duration * 24 * 3600];
											 }

											 NSDictionary* locationNames = nil;
											 if (locationsIDs.count > 0)
												 locationNames = [[NCLocationsManager defaultManager] locationsNamesWithIDs:[locationsIDs allObjects]];
											 
											 EVECharacterName* characterName = nil;
											 if (characterIDs.count > 0)
												 characterName = [EVECharacterName characterNameWithIDs:[characterIDs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)]]]
																										  cachePolicy:NSURLRequestUseProtocolCachePolicy
																												error:nil
																									  progressHandler:nil];
											 
											 for (NCMarketOrdersViewControllerDataRow* row in rows) {
												 row.location = locationNames[@(row.marketOrder.stationID)];
												 if (characterName)
													 row.characterName = characterName.characters[@(row.marketOrder.charID)];
											 }
											 
											 [openOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"expireDate" ascending:YES]]];
											 [closedOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"expireDate" ascending:NO]]];
											 data.openOrders = openOrders;
											 data.closedOrders = closedOrders;
											 
											 data.currentTime = marketOrders.currentTime;
											 data.cacheDate = marketOrders.cacheDate;
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

- (void) update {
	[super update];
	NCMarketOrdersViewControllerData* data = self.data;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

@end

//
//  NCMarketOrdersViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 17.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMarketOrdersViewController.h"
#import <EVEAPI/EVEAPI.h>
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
		[aCoder encodeObject:self.characterName forKey:@"characterName"];
}

@end

@implementation NCMarketOrdersViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.openOrders = [aDecoder decodeObjectForKey:@"openOrders"];
		self.closedOrders = [aDecoder decodeObjectForKey:@"closedOrders"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		if (!self.openOrders)
			self.openOrders = @[];
		if (!self.closedOrders)
			self.closedOrders = @[];
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
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;
@property (nonatomic, strong) NCAccount* account;
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
		
		NCMarketOrdersViewControllerDataRow* row = [sender object];
		NCDBInvType* type = self.types[@(row.marketOrder.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:row.marketOrder.typeID];
			if (type)
				self.types[@(row.marketOrder.typeID)] = type;
		}
		controller.typeID = [type objectID];
	}
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCMarketOrdersViewControllerDataRow* row = [sender object];
		NCDBInvType* type = self.types[@(row.marketOrder.typeID)];
		if (!type) {
			type = [self.databaseManagedObjectContext invTypeWithTypeID:row.marketOrder.typeID];
			if (type)
				self.types[@(row.marketOrder.typeID)] = type;
		}

		return type != nil;
	}
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	return data.openOrders.count + data.closedOrders.count > 0 ? 2 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	return section == 0 ? data.openOrders.count : data.closedOrders.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	return nil;
}

#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:4];

	[account.managedObjectContext performBlock:^{
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api marketOrdersWithOrderID:0 completionBlock:^(EVEMarketOrders *result, NSError *error) {
			if (error)
				lastError = error;
			progress.completedUnitCount++;
			NCMarketOrdersViewControllerData* data = [NCMarketOrdersViewControllerData new];

			NSMutableSet* locationsIDs = [NSMutableSet new];
			NSMutableSet* characterIDs = [NSMutableSet new];
			
			NSMutableArray* rows = [NSMutableArray new];
			NSMutableArray* openOrders = [NSMutableArray new];
			NSMutableArray* closedOrders = [NSMutableArray new];
			for (EVEMarketOrdersItem* order in result.orders) {
				if (order.duration == 0) //Market operations
					continue;
				
				NCMarketOrdersViewControllerDataRow* row = [NCMarketOrdersViewControllerDataRow new];
				row.marketOrder = order;
				[locationsIDs addObject:@(order.stationID)];
				[characterIDs addObject:@(order.charID)];
				
				[rows addObject:row];
				
				if (order.orderState == EVEOrderStateOpen)
					[openOrders addObject:row];
				else
					[closedOrders addObject:row];
				
				row.expireDate = [order.issued dateByAddingTimeInterval:order.duration * 24 * 3600];
			}
			
			dispatch_group_t finishDispatchGroup = dispatch_group_create();
			__block NSDictionary* locationsNames;
			if (locationsIDs.count > 0) {
				dispatch_group_enter(finishDispatchGroup);
				[[NCLocationsManager defaultManager] requestLocationsNamesWithIDs:[locationsIDs allObjects] completionBlock:^(NSDictionary *result) {
					locationsNames = result;
					dispatch_group_leave(finishDispatchGroup);
					@synchronized(progress) {
						progress.completedUnitCount++;
					}
				}];
			}
			else
				@synchronized(progress) {
					progress.completedUnitCount++;
				}
			
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
					for (NCMarketOrdersViewControllerDataRow* row in rows) {
						row.location = locationsNames[@(row.marketOrder.stationID)];
						if (characterName)
							row.characterName = characterName[@(row.marketOrder.charID)];
					}
					
					[openOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"expireDate" ascending:YES]]];
					[closedOrders sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"expireDate" ascending:NO]]];
					data.openOrders = openOrders;
					data.closedOrders = closedOrders;
					
					data.currentTime = result.eveapi.currentTime;
					data.cacheDate = result.eveapi.cacheDate;
					
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

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCMarketOrdersViewControllerData* data = cacheData;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];

	self.backgrountText = data.openOrders.count > 0 || data.closedOrders.count > 0 ? nil : NSLocalizedString(@"No Results", nil);

	completionBlock();
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCMarketOrdersViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	NCMarketOrdersViewControllerDataRow* row = indexPath.section == 0 ? data.openOrders[indexPath.row] : data.closedOrders[indexPath.row];
	
	NCMarketOrdersCell* cell = (NCMarketOrdersCell*) tableViewCell;
	cell.object = row;
	
	NCDBInvType* type = self.types[@(row.marketOrder.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:row.marketOrder.typeID];
		if (type)
			self.types[@(row.marketOrder.typeID)] = type;
	}

	if (type) {
		cell.typeImageView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.titleLabel.text = type.typeName;
	}
	else {
		cell.typeImageView.image = self.unknownTypeIcon.image.image;
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
		cell.expireLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Expires in %@", nil), [NSString stringWithTimeLeft:expireInTime componentsLimit:2]];
	else
		cell.expireLabel.text = NSLocalizedString(@"Expired", nil);
	
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
	
	cell.priceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Price: %@ ISK", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.marketOrder.price)]];
	cell.quantityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Qty: %@ / %@", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:row.marketOrder.volRemaining],
							   [NSNumberFormatter neocomLocalizedStringFromInteger:row.marketOrder.volEntered]
							   ];
	
	if (row.characterName)
		cell.issuedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Issued %@ by %@", nil), [self.dateFormatter stringFromDate:row.marketOrder.issued], row.characterName];
	else
		cell.issuedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Issued %@", nil), [self.dateFormatter stringFromDate:row.marketOrder.issued]];
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

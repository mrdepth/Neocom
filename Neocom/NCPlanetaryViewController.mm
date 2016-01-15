//
//  NCPlanetaryViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPlanetaryViewController.h"
#import "UIColor+Neocom.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingEngine.h"

@interface NCPlanetaryViewControllerDataColony : NSObject<NSCoding>
@property (nonatomic, strong) EVEPlanetaryColoniesItem* colony;
@property (nonatomic, strong) EVEPlanetaryPins* pins;
@property (nonatomic, strong) EVEPlanetaryRoutes* routes;
@property (nonatomic, assign) float security;
@property (nonatomic, strong) NSArray* facilities;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end


@interface NCPlanetaryViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* colonies;
@end


@implementation NCPlanetaryViewControllerDataColony

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.colony = [aDecoder decodeObjectForKey:@"colony"];
		self.security = [aDecoder decodeFloatForKey:@"security"];
		
		self.facilities = [aDecoder decodeObjectForKey:@"facilities"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];

		self.pins = [aDecoder decodeObjectForKey:@"pins"];
		self.routes = [aDecoder decodeObjectForKey:@"routes"];

		if (!self.facilities)
			self.facilities = @[];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.colony)
		[aCoder encodeObject:self.colony forKey:@"colony"];
	[aCoder encodeFloat:self.security forKey:@"security"];
	
	[aCoder encodeObject:self.facilities forKey:@"facilities"];
	[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];

	[aCoder encodeObject:self.pins forKey:@"pins"];
	[aCoder encodeObject:self.routes forKey:@"routes"];
}


@end

@implementation NCPlanetaryViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.colonies = [aDecoder decodeObjectForKey:@"colonies"];
		
		if (!self.colonies)
			self.colonies = @[];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.colonies)
		[aCoder encodeObject:self.colonies forKey:@"colonies"];
}

@end


@interface NCPlanetaryViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSMutableDictionary* types;
//@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;
@property (nonatomic, strong) NCAccount* account;

@end

@implementation NCPlanetaryViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	self.unknownTypeIcon = 	[self.databaseManagedObjectContext eveIconWithIconFile:@"74_14"];
	self.types = [NSMutableDictionary new];
//	self.solarSystems = [NSMutableDictionary new];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCPlanetaryViewControllerData* data = self.cacheData;
	return data.colonies.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCPlanetaryViewControllerData* data = self.cacheData;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[section];
	return colony.facilities.count;
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCPlanetaryViewControllerData* data = cacheData;
	self.backgrountText = data.colonies.count > 0 ? nil : NSLocalizedString(@"No Results", nil);
	
	completionBlock();
}


- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	
	[account.managedObjectContext performBlock:^{
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		NCPlanetaryViewControllerData* data = [NCPlanetaryViewControllerData new];
		[api planetaryColoniesWithCompletionBlock:^(EVEPlanetaryColonies *result, NSError *error) {
			progress.completedUnitCount++;
			if (error)
				lastError = error;
			NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
			[databaseManagedObjectContext performBlock:^{
				NSMutableArray* array = [NSMutableArray new];
				dispatch_group_t finishDispatchGroup = dispatch_group_create();
				
				[progress becomeCurrentWithPendingUnitCount:1];
				NSProgress* colonyProgress = [NSProgress progressWithTotalUnitCount:result.colonies.count * 2];
				[progress resignCurrent];
				
				for (EVEPlanetaryColoniesItem* item in result.colonies) {
					NCPlanetaryViewControllerDataColony* colony = [NCPlanetaryViewControllerDataColony new];
					NCDBMapSolarSystem* solarSystem = [databaseManagedObjectContext mapSolarSystemWithSolarSystemID:item.solarSystemID];
					colony.security = solarSystem ? solarSystem.security : 1.0;
					colony.colony = item;

					dispatch_group_enter(finishDispatchGroup);
					[api planetaryPinsWithPlanetID:item.planetID completionBlock:^(EVEPlanetaryPins *pins, NSError *error) {
						if (pins) {
							NSMutableDictionary* facilities = [NSMutableDictionary new];
							for (EVEPlanetaryPinsItem* pin in pins.pins) {
								facilities[@(pin.pinID)] = pin;
							}
							colony.facilities = [facilities allValues];
							colony.currentTime = pins.eveapi.currentTime;
							colony.cacheDate = pins.eveapi.cacheDate;
							colony.pins = pins;
							@synchronized(array) {
								[array addObject:colony];
							}
							@synchronized(colonyProgress) {
								colonyProgress.completedUnitCount++;
							}
							dispatch_group_leave(finishDispatchGroup);
						}
					} progressBlock:nil];
					
					dispatch_group_enter(finishDispatchGroup);
					[api planetaryRoutesWithPlanetID:item.planetID
									 completionBlock:^(EVEPlanetaryRoutes *routes, NSError *error) {
										 colony.routes = routes;
										 @synchronized(colonyProgress) {
											 colonyProgress.completedUnitCount++;
										 }
										 dispatch_group_leave(finishDispatchGroup);
									 } progressBlock:nil];

				}
				
				dispatch_group_notify(finishDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					[array sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"colony.planetName" ascending:YES]]];
					data.colonies = array;
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self saveCacheData:data cacheDate:[NSDate date] expireDate:[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]];
						completionBlock(lastError);
						progress.completedUnitCount++;
					});
				});
			}];

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
	NCPlanetaryViewControllerData* data = self.cacheData;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[indexPath.section];
	EVEPlanetaryPinsItem* row = colony.facilities[indexPath.row];
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	
	NCDBInvType* type = self.types[@(row.typeID)];
	if (!type) {
		type = [self.databaseManagedObjectContext invTypeWithTypeID:row.typeID];
		if (type)
			self.types[@(row.typeID)] = type;
	}
	
	if (type) {
		cell.iconView.image = type.icon ? type.icon.image.image : self.defaultTypeIcon.image.image;
		cell.titleLabel.text = type.typeName;
	}
	else {
		cell.iconView.image = self.unknownTypeIcon.image.image;
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.typeID];
	}

	cell.object = type;
	
	NSDate* currentDate = [NSDate dateWithTimeInterval:[colony.currentTime timeIntervalSinceDate:colony.cacheDate] sinceDate:[NSDate date]];
	

	NSTimeInterval remainsTime = [row.expiryTime timeIntervalSinceDate:currentDate];
	if (remainsTime <= 0 || !row.expiryTime) {
		cell.subtitleLabel.text = NSLocalizedString(@"Expired", nil);
		cell.subtitleLabel.textColor = [UIColor redColor];
	}
	else {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			cell.subtitleLabel.text = [NSString stringWithFormat:@"Expires: %@ (%@)", [self.dateFormatter stringFromDate:row.expiryTime], [NSString stringWithTimeLeft:remainsTime]];
		else
			cell.subtitleLabel.text = [NSString stringWithFormat:@"Expires: %@\n%@", [self.dateFormatter stringFromDate:row.expiryTime], [NSString stringWithTimeLeft:remainsTime]];

		if (remainsTime < 3600 * 24)
			cell.subtitleLabel.textColor = [UIColor yellowColor];
		else
			cell.subtitleLabel.textColor = [UIColor greenColor];
	}

}

- (NSAttributedString*) tableView:(UITableView *)tableView attributedTitleForHeaderInSection:(NSInteger)section {
	NCPlanetaryViewControllerData* data = self.cacheData;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[section];
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f", colony.security] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithSecurity:colony.security]}];
	[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ / %@", colony.colony.planetName, colony.colony.planetTypeName] attributes:nil]];
	return title;
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

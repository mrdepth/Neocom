//
//  NCPlanetaryViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPlanetaryViewController.h"
#import "UIColor+Neocom.h"
#import "EVEPlanetaryPinsItem+Neocom.h"
#import "NSString+Neocom.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCPlanetaryViewControllerDataColony : NSObject<NSCoding>
@property (nonatomic, strong) EVEPlanetaryColoniesItem* colony;
@property (nonatomic, assign) float security;
@property (nonatomic, strong) NSArray* extractors;
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
		
		self.extractors = [aDecoder decodeObjectForKey:@"extractors"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		
		if (!self.extractors)
			self.extractors = @[];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.colony)
		[aCoder encodeObject:self.colony forKey:@"colony"];
	[aCoder encodeFloat:self.security forKey:@"security"];
	
	if (self.extractors)
		[aCoder encodeObject:self.extractors forKey:@"extractors"];
	
	if (self.currentTime)
		[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	if (self.cacheDate)
		[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];
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

@end

@implementation NCPlanetaryViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
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
	NCPlanetaryViewControllerData* data = self.data;
	return data.colonies.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCPlanetaryViewControllerData* data = self.data;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[section];
	return colony.extractors.count;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCPlanetaryViewControllerData* data = [NCPlanetaryViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 EVEPlanetaryColonies* colonies = [EVEPlanetaryColonies planetaryColoniesWithKeyID:account.apiKey.keyID
																														 vCode:account.apiKey.vCode
																												   cachePolicy:cachePolicy
																												   characterID:account.characterID
																														 error:&error
																											   progressHandler:^(CGFloat progress, BOOL *stop) {
																											   }];
											 if (colonies) {
												 NSMutableArray* array = [NSMutableArray new];
												 float dp = colonies.colonies.count > 0 ? 1.0 / colonies.colonies.count : 1.0;
												 for (EVEPlanetaryColoniesItem* item in colonies.colonies) {
													 NCPlanetaryViewControllerDataColony* colony = [NCPlanetaryViewControllerDataColony new];
													 NCDBMapSolarSystem* solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:item.solarSystemID];
													 colony.security = solarSystem ? solarSystem.security : 1.0;
													 colony.colony = item;
													 
													 EVEPlanetaryPins* pins = [EVEPlanetaryPins planetaryPinsWithKeyID:account.apiKey.keyID
																												 vCode:account.apiKey.vCode
																										   cachePolicy:cachePolicy
																										   characterID:account.characterID
																											  planetID:item.planetID
																												 error:&error
																									   progressHandler:^(CGFloat progress, BOOL *stop) {
																									   }];
													 if (pins) {
														 NSMutableArray* extractors = [NSMutableArray new];
														 for (EVEPlanetaryPinsItem* pin in pins.pins) {
															 if (pin.cycleTime) {
																 [extractors addObject:pin];
															 }
														 }
														 colony.extractors = extractors;
														 colony.currentTime = pins.currentTime;
														 colony.cacheDate = pins.cacheDate;

														 [array addObject:colony];
													 }
													 
													 task.progress += dp;
												 }
												 
												 [array sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"colony.planetName" ascending:YES]]];
												 data.colonies = array;
												 
												 
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

- (void) update {
	[super update];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCPlanetaryViewControllerData* data = self.data;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[indexPath.section];
	EVEPlanetaryPinsItem* row = colony.extractors[indexPath.row];
	NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	
	cell.titleLabel.text = row.typeName;
	cell.iconView.image = row.type.icon.image.image;
	cell.object = row.type;
	
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
	NCPlanetaryViewControllerData* data = self.data;
	NCPlanetaryViewControllerDataColony* colony = data.colonies[section];
	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f", colony.security] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithSecurity:colony.security]}];
	[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ / %@", colony.colony.planetName, colony.colony.planetTypeName] attributes:nil]];
	return title;
}

@end

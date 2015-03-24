//
//  NCPlanetaryViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 24.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCPlanetaryViewController.h"

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
@end

@implementation NCPlanetaryViewControllerData
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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCIndustryJobsDetailsViewController"]) {
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
}

@end

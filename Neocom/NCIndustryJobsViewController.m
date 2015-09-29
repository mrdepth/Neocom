//
//  NCIndustryJobsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCIndustryJobsViewController.h"
#import "EVEIndustryJobsItem+Neocom.h"
#import "NCIndustryJobsCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NSDate+DaysAgo.h"
#import "NCIndustryJobsDetailsViewController.h"

@interface NCIndustryJobsViewControllerData: NSObject<NSCoding>
@property (nonatomic, strong) NSArray* activeJobs;
@property (nonatomic, strong) NSArray* finishedJobs;
@property (nonatomic, strong) NSDate* currentTime;
@property (nonatomic, strong) NSDate* cacheDate;
@end

@implementation NCIndustryJobsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.activeJobs = [aDecoder decodeObjectForKey:@"activeJobs"];
		self.finishedJobs = [aDecoder decodeObjectForKey:@"finishedJobs"];
		self.currentTime = [aDecoder decodeObjectForKey:@"currentTime"];
		self.cacheDate = [aDecoder decodeObjectForKey:@"cacheDate"];
		
		if (!self.activeJobs)
			self.activeJobs = @[];
		if (!self.finishedJobs)
			self.finishedJobs = @[];
		
		NSDictionary* locations = [aDecoder decodeObjectForKey:@"locations"];
		NSDictionary* names = [aDecoder decodeObjectForKey:@"names"];
		for (NSArray* array in @[self.activeJobs, self.finishedJobs]) {
			for (EVEIndustryJobsItem* job in array) {
				job.blueprintLocation = locations[@(job.blueprintLocationID)];
				job.outputLocation = locations[@(job.outputLocationID)];
				job.installerName = names[@(job.installerID)];
			}
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.activeJobs)
		[aCoder encodeObject:self.activeJobs forKey:@"activeJobs"];
	else
		self.activeJobs = @[];
	if (self.finishedJobs)
		[aCoder encodeObject:self.finishedJobs forKey:@"finishedJobs"];
	else
		self.finishedJobs = @[];
	
	if (self.currentTime)
		[aCoder encodeObject:self.currentTime forKey:@"currentTime"];
	if (self.cacheDate)
		[aCoder encodeObject:self.cacheDate forKey:@"cacheDate"];

	
	NSMutableDictionary* locations = [NSMutableDictionary new];
	NSMutableDictionary* names = [NSMutableDictionary new];
	
	for (NSArray* array in @[self.activeJobs, self.finishedJobs]) {
		for (EVEIndustryJobsItem* job in array) {
			if (job.blueprintLocationID)
				locations[@(job.blueprintLocationID)] = job.blueprintLocation;
			if (job.outputLocationID)
				locations[@(job.outputLocationID)] = job.outputLocation;
			if (job.installerName)
				names[@(job.installerID)] = job.installerName;
		}
	}
	[aCoder encodeObject:locations forKey:@"locations"];
	[aCoder encodeObject:names forKey:@"names"];
}

@end

@interface NCIndustryJobsViewController ()
@property (nonatomic, strong) NCIndustryJobsViewControllerData* searchResults;
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSMutableDictionary* types;
@property (nonatomic, strong) NSMutableDictionary* solarSystems;
@property (nonatomic, strong) NSMutableDictionary* activities;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, strong) NCDBEveIcon* unknownTypeIcon;
@property (nonatomic, strong) NCAccount* account;

@end

@implementation NCIndustryJobsViewController

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
	self.activities = [NSMutableDictionary new];
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCIndustryJobsDetailsViewController"]) {
		NCIndustryJobsDetailsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.job = [sender object];
		controller.currentDate = self.currentDate;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
    return data.activeJobs.count + data.finishedJobs.count > 0 ? 2 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	return section == 0 ? data.activeJobs.count : data.finishedJobs.count;
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
		NCIndustryJobsViewControllerData* data = [NCIndustryJobsViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		[api industryJobsHistoryWithCompletionBlock:^(EVEIndustryJobsHistory *result, NSError *error) {
			progress.completedUnitCount++;
			if (error)
				lastError = error;
			
			NSMutableArray* activeJobs = [NSMutableArray new];
			NSMutableArray* finishedJobs = [NSMutableArray new];
			
			NSMutableSet* locationsIDs = [NSMutableSet new];
			NSMutableSet* characterIDs = [NSMutableSet new];
			
			for (EVEIndustryJobsItem* job in result.jobs) {
				if (job.blueprintLocationID)
					[locationsIDs addObject:@(job.blueprintLocationID)];
				if (job.outputLocationID)
					[locationsIDs addObject:@(job.outputLocationID)];
				if (job.installerID)
					[characterIDs addObject:@(job.installerID)];
				
				switch (job.status) {
					case EVEIndustryJobStatusActive:
						[activeJobs addObject:job];
						break;
					case EVEIndustryJobStatusPaused:
					case EVEIndustryJobStatusReady:
					case EVEIndustryJobStatusDelivered:
					case EVEIndustryJobStatusCancelled:
					case EVEIndustryJobStatusReverted:
					default:
						[finishedJobs addObject:job];
						break;
				}
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
					for (EVEIndustryJobsItem* job in result.jobs) {
						job.blueprintLocation = locationsNames[@(job.blueprintLocationID)];
						job.outputLocation = locationsNames[@(job.outputLocationID)];
						job.installerName = characterName[@(job.installerID)];
					}
					
					[activeJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:YES]]];
					[finishedJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"completedDate" ascending:NO]]];
					
					data.activeJobs = activeJobs;
					data.finishedJobs = finishedJobs;
					
					data.currentTime = result.eveapi.currentTime;
					data.cacheDate = result.eveapi.cacheDate;
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self saveCacheData:data cacheDate:[NSDate date] expireDate:[result.eveapi localTimeWithServerTime:result.eveapi.cachedUntil]];
						completionBlock(lastError);
						progress.completedUnitCount++;
					});
					
				}
			});
		} progressBlock:nil];
	}];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCIndustryJobsViewControllerData* data = cacheData;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
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
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.cacheData : self.searchResults;
	EVEIndustryJobsItem* row = indexPath.section == 0 ? data.activeJobs[indexPath.row] : data.finishedJobs[indexPath.row];
	
	NCIndustryJobsCell* cell = (NCIndustryJobsCell*) tableViewCell;
	cell.object = row;
	
	NCDBInvType* blueprintType = self.types[@(row.blueprintTypeID)];
	if (!blueprintType) {
		blueprintType = [self.databaseManagedObjectContext invTypeWithTypeID:row.blueprintTypeID];
		if (blueprintType)
			self.types[@(row.blueprintTypeID)] = blueprintType;
	}

	NCDBInvType* productType = self.types[@(row.productTypeID)];
	if (!productType) {
		productType = [self.databaseManagedObjectContext invTypeWithTypeID:row.productTypeID];
		if (productType)
			self.types[@(row.productTypeID)] = productType;
	}

	NCDBRamActivity* activity = self.activities[@(row.activityID)];
	if (!activity) {
		activity = [self.databaseManagedObjectContext ramActivityWithActivityID:row.activityID];
		if (activity)
			self.activities[@(row.activityID)] = activity;
	}

	
	if (blueprintType) {
		cell.typeImageView.image = blueprintType.icon ? blueprintType.icon.image.image : self.defaultTypeIcon.image.image;
		cell.titleLabel.text = blueprintType.typeName;
	}
	else {
		cell.typeImageView.image = self.unknownTypeIcon.image.image;
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.blueprintTypeID];
	}
	
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.endDate];
	cell.activityLabel.text = activity.activityName;
	cell.activityImageView.image = activity.icon.image.image;
	cell.characterLabel.text = row.installerName;
	
	if (row.blueprintLocation.name)
		cell.locationLabel.text = row.blueprintLocation.name;
	else if (row.blueprintLocation.solarSystemID) {
		NCDBMapSolarSystem* solarSystem = self.solarSystems[@(row.blueprintLocation.solarSystemID)];
		if (!solarSystem) {
			solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:row.blueprintLocation.solarSystemID];
			if (solarSystem)
				self.solarSystems[@(row.blueprintLocation.solarSystemID)] = solarSystem;
		};
		cell.locationLabel.text = solarSystem.solarSystemName;
	}
	else
		cell.locationLabel.text = NSLocalizedString(@"Unknown location", nil);

	
	NSString* status = [row localizedStateWithCurrentDate:self.currentDate];
	
	NSTimeInterval remainsTime = [row.endDate timeIntervalSinceDate:self.currentDate];
	UIColor* statusColor;
	
	switch (row.status) {
		case EVEIndustryJobStatusActive:
			statusColor = remainsTime <= 0 ? [UIColor greenColor] : [UIColor yellowColor];
			break;
		case EVEIndustryJobStatusPaused:
			statusColor = [UIColor yellowColor];
			break;
		case EVEIndustryJobStatusReady:
		case EVEIndustryJobStatusDelivered:
			statusColor = [UIColor greenColor];
			break;
		case EVEIndustryJobStatusCancelled:
		case EVEIndustryJobStatusReverted:
		default:
			statusColor = [UIColor redColor];
			break;
	}

	cell.stateLabel.text = status;
	cell.stateLabel.textColor = statusColor;
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

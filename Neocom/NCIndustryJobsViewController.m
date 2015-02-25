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
		
		NSMutableDictionary* types = [NSMutableDictionary new];
		NSMutableDictionary* activities = [NSMutableDictionary new];
		
		for (NSArray* array in @[self.activeJobs, self.finishedJobs]) {
			for (EVEIndustryJobsItem* job in array) {
				if (job.blueprintTypeID) {
					NCDBInvType* type = types[@(job.blueprintTypeID)];
					if (!type) {
						type = [NCDBInvType invTypeWithTypeID:job.blueprintTypeID];
						if (type) {
							types[@(job.blueprintTypeID)] = type;
						}
					}
					job.blueprintType = type;
				}
				
				if (job.productTypeID) {
					NCDBInvType* type = types[@(job.productTypeID)];
					if (!type) {
						type = [NCDBInvType invTypeWithTypeID:job.productTypeID];
						if (type) {
							types[@(job.productTypeID)] = type;
						}
					}
					job.productType = type;
				}
				
				if (job.activityID) {
					NCDBRamActivity* activity = activities[@(job.activityID)];
					if (!activity) {
						activity = [NCDBRamActivity ramActivityWithActivityID:job.activityID];
						if (activity) {
							activities[@(job.activityID)] = activity;
						}
					}
					job.activity = activity;
				}

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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
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
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
    return data.activeJobs.count + data.finishedJobs.count > 0 ? 2 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	return section == 0 ? data.activeJobs.count : data.finishedJobs.count;
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccount* account = [NCAccount currentAccount];
	if (!account) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	
	NCIndustryJobsViewControllerData* data = [NCIndustryJobsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BOOL corporate = account.accountType == NCAccountTypeCorporate;
											 
											 EVEIndustryJobs* industryJobs = [EVEIndustryJobs industryJobsWithKeyID:account.apiKey.keyID
																											  vCode:account.apiKey.vCode
																										cachePolicy:cachePolicy
																										characterID:account.characterID
																										  corporate:corporate
																											  error:&error
																									progressHandler:^(CGFloat progress, BOOL *stop) {
																										task.progress = progress;
																									}];
											 if (industryJobs) {
												 cacheExpireDate = industryJobs.cacheExpireDate;
												 
												 NSMutableArray* activeJobs = [NSMutableArray new];
												 NSMutableArray* finishedJobs = [NSMutableArray new];
												 
												 NSMutableSet* locationsIDs = [NSMutableSet new];
												 NSMutableSet* characterIDs = [NSMutableSet new];
												 
												 NSMutableDictionary* types = [NSMutableDictionary new];
												 NSMutableDictionary* activities = [NSMutableDictionary new];

												 for (EVEIndustryJobsItem* job in industryJobs.jobs) {
													 if (job.blueprintLocationID)
														 [locationsIDs addObject:@(job.blueprintLocationID)];
													 if (job.outputLocationID)
														 [locationsIDs addObject:@(job.outputLocationID)];
													 if (job.installerID)
														 [characterIDs addObject:@(job.installerID)];
													 
													 if (job.productTypeID) {
														 NCDBInvType* type = types[@(job.productTypeID)];
														 if (!type) {
															 type = [NCDBInvType invTypeWithTypeID:job.productTypeID];
															 if (type) {
																 types[@(job.productTypeID)] = type;
															 }
														 }
														 job.productTypeID = type.typeID;
													 }
													 
													 if (job.blueprintTypeID) {
														 NCDBInvType* type = types[@(job.blueprintTypeID)];
														 if (!type) {
															 type = [NCDBInvType invTypeWithTypeID:job.blueprintTypeID];
															 if (type) {
																 types[@(job.blueprintTypeID)] = type;
															 }
														 }
														 job.blueprintType = type;
													 }
													 
													 if (job.activityID) {
														 NCDBRamActivity* activity = activities[@(job.activityID)];
														 if (!activity) {
															 activity = [NCDBRamActivity ramActivityWithActivityID:job.activityID];
															 if (activity) {
																 activities[@(job.activityID)] = activity;
															 }
														 }
														 job.activity = activity;
													 }
//													 if (job.completed)
//														 [finishedJobs addObject:job];
//													 else
														 [activeJobs addObject:job];
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
                         
												 for (EVEIndustryJobsItem* job in industryJobs.jobs) {
													 job.blueprintLocation = locationNames[@(job.blueprintLocationID)];
													 job.outputLocation = locationNames[@(job.outputLocationID)];
													 job.installerName = characterName.characters[@(job.installerID)];
												 }
												 
												 [activeJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:YES]]];
												 [finishedJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"completedDate" ascending:NO]]];
												 
												 data.activeJobs = activeJobs;
												 data.finishedJobs = finishedJobs;
												 
												 data.currentTime = industryJobs.currentTime;
												 data.cacheDate = industryJobs.cacheDate;

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
	NCIndustryJobsViewControllerData* data = self.data;
	self.currentDate = [NSDate dateWithTimeInterval:[data.currentTime timeIntervalSinceDate:data.cacheDate] sinceDate:[NSDate date]];
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
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	EVEIndustryJobsItem* row = indexPath.section == 0 ? data.activeJobs[indexPath.row] : data.finishedJobs[indexPath.row];
	
	NCIndustryJobsCell* cell = (NCIndustryJobsCell*) tableViewCell;
	cell.object = row;
	
	if (row.blueprintType) {
		cell.typeImageView.image = row.blueprintType.icon ? row.blueprintType.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.titleLabel.text = row.blueprintType.typeName;
	}
	else {
		cell.typeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"74_14"] image] image];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.blueprintType];
	}
	
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.endDate];
	cell.activityLabel.text = row.activity.activityName;
	cell.activityImageView.image = row.activity.icon.image.image;
	cell.characterLabel.text = row.installerName;
	cell.locationLabel.text = row.blueprintLocation.name;
	
	NSString* status = [row localizedStateWithCurrentDate:self.currentDate];
	UIColor* statusColor = nil;
	statusColor = [UIColor yellowColor];
	cell.stateLabel.text = status;
	cell.stateLabel.textColor = statusColor;
}

@end

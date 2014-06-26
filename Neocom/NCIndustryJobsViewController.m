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
		
		NSMutableDictionary* types = [NSMutableDictionary new];
		NSMutableDictionary* activities = [NSMutableDictionary new];
		
		for (NSArray* array in @[self.activeJobs, self.finishedJobs]) {
			for (EVEIndustryJobsItem* job in array) {
				job.installedItemLocation = locations[@(job.installedItemLocationID)];
				job.outputLocation = locations[@(job.outputLocationID)];
				job.installerName = names[@(job.installerID)];
				
				if (job.installedItemTypeID) {
					NCDBInvType* type = types[@(job.installedItemTypeID)];
					if (!type) {
						type = [NCDBInvType invTypeWithTypeID:job.installedItemTypeID];
						if (type) {
							types[@(job.installedItemTypeID)] = type;
						}
					}
					job.installedItemType = type;
				}
				
				if (job.outputTypeID) {
					NCDBInvType* type = types[@(job.outputTypeID)];
					if (!type) {
						type = [NCDBInvType invTypeWithTypeID:job.outputTypeID];
						if (type) {
							types[@(job.outputTypeID)] = type;
						}
					}
					job.outputType = type;
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
			if (job.installedItemLocation)
				locations[@(job.installedItemLocationID)] = job.installedItemLocation;
			if (job.outputLocation)
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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCIndustryJobsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return 72;
	else
		return 102;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView offscreenCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
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
													 if (job.installedItemLocationID)
														 [locationsIDs addObject:@(job.installedItemLocationID)];
													 if (job.outputLocationID)
														 [locationsIDs addObject:@(job.outputLocationID)];
													 if (job.installerID)
														 [characterIDs addObject:@(job.installerID)];
													 
													 if (job.installedItemTypeID) {
														 NCDBInvType* type = types[@(job.installedItemTypeID)];
														 if (!type) {
															 type = [NCDBInvType invTypeWithTypeID:job.installedItemTypeID];
															 if (type) {
																 types[@(job.installedItemTypeID)] = type;
															 }
														 }
														 job.installedItemType = type;
													 }
													 
													 if (job.outputTypeID) {
														 NCDBInvType* type = types[@(job.outputTypeID)];
														 if (!type) {
															 type = [NCDBInvType invTypeWithTypeID:job.outputTypeID];
															 if (type) {
																 types[@(job.outputTypeID)] = type;
															 }
														 }
														 job.outputType = type;
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
													 if (job.completed)
														 [finishedJobs addObject:job];
													 else
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
													 job.installedItemLocation = locationNames[@(job.installedItemLocationID)];
													 job.outputLocation = locationNames[@(job.outputLocationID)];
													 job.installerName = characterName.characters[@(job.installerID)];
												 }
												 [activeJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"endProductionTime" ascending:YES]]];
												 [finishedJobs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"endProductionTime" ascending:NO]]];
												 
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

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCIndustryJobsViewControllerData* data = tableView == self.tableView ? self.data : self.searchResults;
	EVEIndustryJobsItem* row = indexPath.section == 0 ? data.activeJobs[indexPath.row] : data.finishedJobs[indexPath.row];
	
	NCIndustryJobsCell* cell = (NCIndustryJobsCell*) tableViewCell;
	cell.object = row;
	
	if (row.installedItemType) {
		cell.typeImageView.image = row.installedItemType.icon ? row.installedItemType.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
		cell.titleLabel.text = row.installedItemType.typeName;
	}
	else {
		cell.typeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"74_14"] image] image];
		cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), row.installedItemTypeID];
	}
	
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.endProductionTime];
	cell.activityLabel.text = row.activity.activityName;
	cell.activityImageView.image = row.activity.icon.image.image;
	cell.characterLabel.text = row.installerName;
	cell.locationLabel.text = row.installedItemLocation.name;
	
	NSString* status = [row localizedStateWithCurrentDate:self.currentDate];
	UIColor* statusColor = nil;
	if (!row.completed) {
		statusColor = [UIColor yellowColor];
	}
	else {
		if (row.completedStatus == 1) {
			statusColor = [UIColor greenColor];
		}
		else
			statusColor = [UIColor redColor];
	}
	cell.stateLabel.text = status;
	cell.stateLabel.textColor = statusColor;
}

@end

//
//  NCZKillBoardSearchResultsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCZKillBoardSearchResultsViewController.h"
#import "EVEKillLogKill+Neocom.h"
#import "EVEKillLogVictim+Neocom.h"
#import "EVEzKillBoardAPI.h"
#import "NCKillMailsCell.h"
#import "UIColor+Neocom.h"
#import "UIAlertView+Error.h"
#import "NCKillMailDetailsViewController.h"

@interface NCZKillBoardSearchResultsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* kills;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSDate* date;
@end

@interface NCZKillBoardSearchResultsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCZKillBoardSearchResultsViewControllerDataSection

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.kills = [aDecoder decodeObjectForKey:@"kills"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.date = [aDecoder decodeObjectForKey:@"date"];
		for (EVEKillLogKill* kill in self.kills) {
			kill.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID];
			kill.victim.shipType = [NCDBInvType invTypeWithTypeID:kill.victim.shipTypeID];
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.kills)
		[aCoder encodeObject:self.kills forKey:@"kills"];
	
	if (self.title)
		[aCoder encodeObject:self.title forKey:@"title"];
	
	if (self.date)
		[aCoder encodeObject:self.date forKey:@"date"];
}

@end

@implementation NCZKillBoardSearchResultsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.sections = [aDecoder decodeObjectForKey:@"sections"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.sections)
		[aCoder encodeObject:self.sections forKey:@"sections"];
}

@end


@interface NCZKillBoardSearchResultsViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@end

@implementation NCZKillBoardSearchResultsViewController

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
	[self.dateFormatter setDateFormat:@"HH:mm"];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCKillMailDetailsViewController"]) {
		NCKillMailDetailsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.killMail = [[NCKillMail alloc] initWithKillLogKill:sender];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCZKillBoardSearchResultsViewControllerData* data = self.data;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCZKillBoardSearchResultsViewControllerData* data = self.data;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[sectionIndex];
	return section.kills.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCZKillBoardSearchResultsViewControllerData* data = self.data;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[sectionIndex];
	return section.title;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCZKillBoardSearchResultsViewControllerData* data = self.data;

	EVEKillLogKill* kill = nil;
	if (indexPath.row > 0) {
		NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section];
		kill = section.kills[indexPath.row - 1];
	}
	else if (indexPath.section > 0) {
		NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section - 1];
		kill = [section.kills lastObject];
	}

	__block NSError* error = nil;
	__block EVEzKillBoardSearch* search = nil;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableDictionary* filter = [self.filter mutableCopy];
											 filter[EVEzKillBoardSearchFilterLimitKey] = @(1);
											 if (kill)
												 filter[EVEzKillBoardSearchFilterBeforeKillIDKey] = @(kill.killID);
											 search = [EVEzKillBoardSearch searchWithFilter:filter
																					  error:&error
																			progressHandler:^(CGFloat progress, BOOL *stop) {
																				task.progress = progress;
																			}];
											 for (EVEKillLogKill* kill in search.kills) {
												 kill.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID];
												 kill.victim.shipType = [NCDBInvType invTypeWithTypeID:kill.victim.shipTypeID];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 if (error)
										 [UIAlertView alertViewWithError:error];
									 else {
										 if (search.kills.count > 0)
											 [self performSegueWithIdentifier:@"NCKillMailDetailsViewController" sender:search.kills[0]];
									 }
								 }
							 }];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	NSMutableArray* components = [NSMutableArray new];
	[self.filter enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
	}];
	return [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), @([[components componentsJoinedByString:@","] hash])];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCZKillBoardSearchResultsViewControllerData* data = self.data;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEKillLogKill* row = section.kills[indexPath.row];
	
	NCKillMailsCell* cell = (NCKillMailsCell*) tableViewCell;
	cell.object = row;
	cell.typeImageView.image = row.victim.shipType.icon ? row.victim.shipType.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.titleLabel.text = row.victim.shipType.typeName;
	
	if (row.solarSystem) {
		NSString* ss = [NSString stringWithFormat:@"%.1f", row.solarSystem.security];
		NSString* s = [NSString stringWithFormat:@"%@ %@", ss, row.solarSystem.solarSystemName];
		NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
		[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:row.solarSystem.security] range:NSMakeRange(0, ss.length)];
		cell.locationLabel.attributedText = title;
	}
	else {
		cell.locationLabel.attributedText = nil;
		cell.locationLabel.text = NSLocalizedString(@"Unknown Location", nil);
	}
	
	
	cell.characterLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Victim: %@", nil), row.victim.characterName];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.killTime];
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCZKillBoardSearchResultsViewControllerData* data = [NCZKillBoardSearchResultsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableDictionary* filter = [self.filter mutableCopy];
											 filter[EVEzKillBoardSearchFilterNoItemsIDKey] = @"";
											 filter[EVEzKillBoardSearchFilterNoAttackersIDKey] = @"";
											 EVEzKillBoardSearch* search = [EVEzKillBoardSearch searchWithFilter:filter
																										   error:&error
																								 progressHandler:^(CGFloat progress, BOOL *stop) {
																									 task.progress = progress;
																								 }];
											 
											 if (search) {
												 NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
												 [dateFormatter setDateFormat:@"yyyy.MM.dd"];
												 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
												 NSMutableDictionary* sections = [NSMutableDictionary new];
												 
												 for (EVEKillLogKill* kill in search.kills) {
													 kill.solarSystem = [NCDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID];
													 kill.victim.shipType = [NCDBInvType invTypeWithTypeID:kill.victim.shipTypeID];
													 
													 NCZKillBoardSearchResultsViewControllerDataSection* section = nil;
													 NSString* key = [dateFormatter stringFromDate:kill.killTime];
													 section = sections[key];
													 if (!section) {
														 sections[key] = section = [NCZKillBoardSearchResultsViewControllerDataSection new];
														 section.title = key;
														 section.kills = [NSMutableArray new];
														 section.date = kill.killTime;
													 }

													 [(NSMutableArray*) section.kills addObject:kill];
												 }
												 data.sections = [[sections allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
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

- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60 * 24;
}

@end

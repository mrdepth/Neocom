//
//  NCZKillBoardSearchResultsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCZKillBoardSearchResultsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCKillMailsCell.h"
#import "UIColor+Neocom.h"
#import "NCKillMailDetailsViewController.h"
#import "NCKillMail.h"
#import "UIAlertController+Neocom.h"

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
@property (nonatomic, assign) BOOL loading;
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
	
	NSMutableArray* components = [NSMutableArray new];
	[self.filter enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
	}];
	self.cacheRecordID = [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), @([[components componentsJoinedByString:@","] hash])];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCKillMailDetailsViewController"]) {
		NCKillMailDetailsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.killMail = [[NCKillMail alloc] initWithKillMailsKill:sender databaseManagedObjectContext:self.databaseManagedObjectContext];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCZKillBoardSearchResultsViewControllerData* data = self.cacheData;
	return data.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCZKillBoardSearchResultsViewControllerData* data = self.cacheData;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[sectionIndex];
	return section.kills.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCZKillBoardSearchResultsViewControllerData* data = self.cacheData;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[sectionIndex];
	return section.title;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.loading)
		return;
	
	NCZKillBoardSearchResultsViewControllerData* data = self.cacheData;

	EVEKillMailsKill* kill = nil;
	if (indexPath.row > 0) {
		NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section];
		kill = section.kills[indexPath.row - 1];
	}
	else if (indexPath.section > 0) {
		NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section - 1];
		kill = [section.kills lastObject];
	}

	NSMutableDictionary* filter = [self.filter mutableCopy];
	filter[EVEzKillBoardSearchFilterLimitKey] = @(1);
	if (kill)
		filter[EVEzKillBoardSearchFilterBeforeKillIDKey] = @(kill.killID);

	self.loading = YES;
	[[EVEzKillBoardAPI new] searchWithFilter:filter completionBlock:^(EVEzKillBoardSearch *result, NSError *error) {
		self.loading = NO;
		if (result.kills.count > 0)
			[self performSegueWithIdentifier:@"NCKillMailDetailsViewController" sender:result.kills[0]];
		else if (error)
			[self presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
	}];
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCZKillBoardSearchResultsViewControllerData* data = self.cacheData;
	NCZKillBoardSearchResultsViewControllerDataSection* section = data.sections[indexPath.section];
	EVEKillMailsKill* row = section.kills[indexPath.row];
	
	NCKillMailsCell* cell = (NCKillMailsCell*) tableViewCell;
	cell.object = row;
	NCDBInvType* shipType = [self.databaseManagedObjectContext invTypeWithTypeID:row.victim.shipTypeID];
	cell.typeImageView.image = shipType.icon.image.image ?: [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
	cell.titleLabel.text = shipType.typeName;
	
	NCDBMapSolarSystem* solarSystem = [self.databaseManagedObjectContext mapSolarSystemWithSolarSystemID:row.solarSystemID];
	if (solarSystem) {
		NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.security];
		NSString* s = [NSString stringWithFormat:@"%@ %@", ss, solarSystem.solarSystemName];
		NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:s];
		[title addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.security] range:NSMakeRange(0, ss.length)];
		cell.locationLabel.attributedText = title;
	}
	else {
		cell.locationLabel.attributedText = nil;
		cell.locationLabel.text = NSLocalizedString(@"Unknown Location", nil);
	}
	
	
	cell.characterLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Victim: %@", nil), row.victim.characterName];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.killTime];
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	
	EVEzKillBoardAPI* api = [[EVEzKillBoardAPI alloc] initWithCachePolicy:cachePolicy];
	NSMutableDictionary* filter = [self.filter mutableCopy];
	filter[EVEzKillBoardSearchFilterNoItemsIDKey] = @"";
	filter[EVEzKillBoardSearchFilterNoAttackersIDKey] = @"";
	[api searchWithFilter:filter completionBlock:^(EVEzKillBoardSearch *result, NSError *error) {
		progress.completedUnitCount++;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NCZKillBoardSearchResultsViewControllerData* data = [NCZKillBoardSearchResultsViewControllerData new];
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy.MM.dd"];
			[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
			NSMutableDictionary* sections = [NSMutableDictionary new];
			
			for (EVEKillMailsKill* kill in result.kills) {
				
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
			
			progress.completedUnitCount++;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
				completionBlock(error);
			});

		});
	}];
}

@end

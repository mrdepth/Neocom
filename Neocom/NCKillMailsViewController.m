//
//  NCKillMailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMailsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCKillMailsCell.h"
#import "UIColor+Neocom.h"
#import "NCKillMailDetailsViewController.h"

@interface NCKillMailsViewControllerDataSection : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* kills;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSDate* date;
@end

@interface NCKillMailsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* kills;
@property (nonatomic, strong) NSArray* losses;
@end

@implementation NCKillMailsViewControllerDataSection

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

@implementation NCKillMailsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.kills = [aDecoder decodeObjectForKey:@"kills"];
		self.losses = [aDecoder decodeObjectForKey:@"losses"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.kills)
		[aCoder encodeObject:self.kills forKey:@"kills"];
	
	if (self.losses)
		[aCoder encodeObject:self.losses forKey:@"losses"];
}

@end

@interface NCKillMailsViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NCAccount* account;

@end

@implementation NCKillMailsViewController

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
	self.account = [NCAccount currentAccount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	[self.tableView reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCKillMailDetailsViewController"]) {
		NCKillMailDetailsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.killMail = [[NCKillMail alloc] initWithKillMailsKill:[sender object] databaseManagedObjectContext:self.databaseManagedObjectContext];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCKillMailsViewControllerData* data = self.cacheData;
	return self.segmentedControl.selectedSegmentIndex == 0 ? data.kills.count : data.losses.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCKillMailsViewControllerData* data = self.cacheData;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[sectionIndex] : data.losses[sectionIndex];
	return section.kills.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCKillMailsViewControllerData* data = self.cacheData;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[sectionIndex] : data.losses[sectionIndex];
	return section.title;
}


#pragma mark - NCTableViewController

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	NCAccount* account = self.account;
	if (!account) {
		completionBlock(nil);
		return;
	}
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:3];
	
	[account.managedObjectContext performBlock:^{
		__block NSError* lastError = nil;
		NCKillMailsViewControllerData* data = [NCKillMailsViewControllerData new];
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:account.eveAPIKey cachePolicy:cachePolicy];
		BOOL corporate = api.apiKey.corporate;
		[account loadCharacterInfoWithCompletionBlock:^(EVECharacterInfo *characterInfo, NSError *error) {
			progress.completedUnitCount++;
			[api killMailsFromID:0 rowCount:200 completionBlock:^(EVEKillMails *result, NSError *error) {
				progress.completedUnitCount++;
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					@autoreleasepool {
						if (result) {
							NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
							[dateFormatter setDateFormat:@"yyyy.MM.dd"];
							[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
							
							NSMutableDictionary* kills = [NSMutableDictionary new];
							NSMutableDictionary* losses = [NSMutableDictionary new];
							
							for (EVEKillMailsKill* kill in result.kills) {
								NCKillMailsViewControllerDataSection* section = nil;
								NSString* key = [dateFormatter stringFromDate:kill.killTime];
								if ((corporate && kill.victim.corporationID == characterInfo.corporationID) ||
									(!corporate && kill.victim.characterID == characterInfo.characterID)) {
									section = losses[key];
									if (!section) {
										losses[key] = section = [NCKillMailsViewControllerDataSection new];
										section.title = key;
										section.kills = [NSMutableArray new];
										section.date = kill.killTime;
									}
								}
								else {
									section = kills[key];
									if (!section) {
										kills[key] = section = [NCKillMailsViewControllerDataSection new];
										section.title = key;
										section.kills = [NSMutableArray new];
										section.date = kill.killTime;
									}
								}
								[(NSMutableArray*) section.kills addObject:kill];
							}
							data.kills = [[kills allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
							data.losses = [[losses allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
						}
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
							completionBlock(lastError);
							progress.completedUnitCount++;
						});
					}
				});
			} progressBlock:nil];
		}];
	}];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCKillMailsViewControllerData* data = self.cacheData;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[indexPath.section] : data.losses[indexPath.section];
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
	
	
	EVEKillMailsAttacker* attacker = nil;
	for (attacker in row.attackers)
		if (attacker.finalBlow == YES)
			break;
	if (!attacker && row.attackers.count > 0)
		attacker = row.attackers[0];
	
	cell.characterLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ kills %@", nil), attacker.characterName, row.victim.characterName];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.killTime];
}

- (void) didChangeAccount:(NSNotification *)notification {
	[super didChangeAccount:notification];
	self.account = [NCAccount currentAccount];
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

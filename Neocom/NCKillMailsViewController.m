//
//  NCKillMailsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCKillMailsViewController.h"
#import "EVEKillLogKill+Neocom.h"
#import "EVEKillLogVictim+Neocom.h"
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
		for (EVEKillLogKill* kill in self.kills) {
			kill.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID error:nil];
			kill.victim.shipType = [EVEDBInvType invTypeWithTypeID:kill.victim.shipTypeID error:nil];
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
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onChangeMode:(id)sender {
	[self update];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCKillMailDetailsViewController"]) {
		NCKillMailDetailsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.killMail = [[NCKillMail alloc] initWithKillLogKill:[sender object]];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCKillMailsViewControllerData* data = self.data;
	return self.segmentedControl.selectedSegmentIndex == 0 ? data.kills.count : data.losses.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCKillMailsViewControllerData* data = self.data;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[sectionIndex] : data.losses[sectionIndex];
	return section.kills.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NCKillMailsViewControllerData* data = self.data;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[sectionIndex] : data.losses[sectionIndex];
	return section.title;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCKillMailsViewControllerData* data = self.data;
	NCKillMailsViewControllerDataSection* section = self.segmentedControl.selectedSegmentIndex == 0 ? data.kills[indexPath.section] : data.losses[indexPath.section];
	EVEKillLogKill* row = section.kills[indexPath.row];
	
	NCKillMailsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.object = row;
	cell.typeImageView.image = [UIImage imageNamed:row.victim.shipType.typeSmallImageName];
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
	
	
	EVEKillLogAttacker* attacker = nil;
	for (attacker in row.attackers)
		if (attacker.finalBlow == YES)
			break;
	if (!attacker && row.attackers.count > 0)
		attacker = row.attackers[0];

	cell.characterLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ kills %@", nil), attacker.characterName, row.victim.characterName];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:row.killTime];
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
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
	
	NCKillMailsViewControllerData* data = [NCKillMailsViewControllerData new];
	__block NSDate* cacheExpireDate = [NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 BOOL corporate = account.accountType == NCAccountTypeCorporate;
											 EVEKillLog* killLog = [EVEKillLog killLogWithKeyID:account.apiKey.keyID
																						  vCode:account.apiKey.vCode
																					cachePolicy:cachePolicy
																					characterID:account.characterID
																				   beforeKillID:0
																					  corporate:corporate
																						  error:&error
																				progressHandler:^(CGFloat progress, BOOL *stop) {
																					task.progress = progress;
																				}];
											 
											 if (killLog) {
												 cacheExpireDate = killLog.cacheExpireDate;
												 NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
												 [dateFormatter setDateFormat:@"yyyy.MM.dd"];
												 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
												 NSMutableDictionary* kills = [NSMutableDictionary new];
												 NSMutableDictionary* losses = [NSMutableDictionary new];

												 for (EVEKillLogKill* kill in killLog.kills) {
													 kill.solarSystem = [EVEDBMapSolarSystem mapSolarSystemWithSolarSystemID:kill.solarSystemID error:nil];
													 kill.victim.shipType = [EVEDBInvType invTypeWithTypeID:kill.victim.shipTypeID error:nil];
													 
													 NCKillMailsViewControllerDataSection* section = nil;
													 NSString* key = [dateFormatter stringFromDate:kill.killTime];
													 if ((corporate && kill.victim.corporationID == account.corporationSheet.corporationID) ||
														 (!corporate && kill.victim.characterID == account.characterID)) {
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

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadFromCache];
}


@end

//
//  NCFittingAPISearchResultsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAPISearchResultsViewController.h"
#import "NeocomAPI.h"
#import "NCFittingAPISearchResultsCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingShipViewController.h"

@interface NCFittingAPISearchResultsViewController ()
@property (nonatomic, strong) NSString* order;
@property (nonatomic, strong) NSMutableDictionary* types;
@end

@implementation NCFittingAPISearchResultsViewController

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
	self.order = @"dps";
	self.types = [NSMutableDictionary new];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)onChangeOrder:(id)sender {
	switch (self.segmentedControl.selectedSegmentIndex) {
		case 0:
			self.order = @"dps";
			break;
		case 1:
			self.order = @"ehp";
			break;
		case 2:
			self.order = @"maxRange";
			break;
		case 3:
			self.order = @"falloff";
			break;
	}

	[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		NAPISearchItem* item = [sender object];

		destinationViewController.fit = [[NCShipFit alloc] initWithAPILoadout:item];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.data ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray* rows = self.data;
    return rows.count;
}


#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	__block NAPISearch* search = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 search = [NAPISearch searchWithCriteria:self.criteria order:self.order cachePolicy:cachePolicy error:&error progressHandler:^(CGFloat progress, BOOL *stop) {
												 task.progress = progress;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:search.loadouts withCacheDate:[NSDate date] expireDate:search.cacheExpireDate];
									 }
								 }
							 }];
}

- (NSString*) recordID {
	NSMutableArray* components = [NSMutableArray new];
	[self.criteria enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[components addObject:[NSString stringWithFormat:@"%@.%@", key, obj]];
	}];
	return [NSString stringWithFormat:@"%@.%@.%lu", NSStringFromClass(self.class), self.order, (unsigned long)[[components componentsJoinedByString:@","] hash]];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* rows = self.data;
	NAPISearchItem* item = rows[indexPath.row];
	
	NCFittingAPISearchResultsCell *cell = (NCFittingAPISearchResultsCell*) tableViewCell;
	
	NCDBInvType* ship = self.types[@(item.typeID)];
	if (!ship) {
		ship = [NCDBInvType invTypeWithTypeID:item.typeID];
		if (ship)
			self.types[@(item.typeID)] = ship;
	}
	
	cell.titleLabel.text = ship.typeName;
	cell.iconImageView.image = ship.icon ? ship.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.object = item;
	
	if (item.flags & NeocomAPIFlagHybridTurrets)
		cell.weaponTypeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"13_06"] image] image];
	else if (item.flags & NeocomAPIFlagLaserTurrets)
		cell.weaponTypeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"13_10"] image] image];
	else if (item.flags & NeocomAPIFlagProjectileTurrets)
		cell.weaponTypeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"12_14"] image] image];
	else if (item.flags & NeocomAPIFlagMissileLaunchers)
		cell.weaponTypeImageView.image = [[[NCDBEveIcon eveIconWithIconFile:@"12_12"] image] image];
	else
		cell.weaponTypeImageView.image = [UIImage imageNamed:@"turrets.png"];
	
	NSString* tankType;
	if (item.flags & NeocomAPIFlagActiveTank) {
		if (item.flags & NeocomAPIFlagArmorTank) {
			cell.tankTypeImageView.image = [UIImage imageNamed:@"armorRepairer.png"];
			tankType = NSLocalizedString(@"Active Armor", nil);
		}
		else {
			cell.tankTypeImageView.image = [UIImage imageNamed:@"shieldBooster.png"];
			tankType = NSLocalizedString(@"Active Shield", nil);
		}
	}
	else {
		cell.tankTypeImageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
		tankType = NSLocalizedString(@"Passive", nil);
	}
	
	cell.ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ EHP, %@", nil),
						  [NSNumberFormatter neocomLocalizedStringFromInteger:item.ehp],
						  tankType];
	cell.turretDpsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil),
								[NSNumberFormatter neocomLocalizedStringFromInteger:item.turretDps]];
	cell.droneDpsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.droneDps]];
	cell.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Speed: %@ m/s", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.speed]];
	cell.maxRangeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Optimal: %@ m", nil),
							   [NSNumberFormatter neocomLocalizedStringFromInteger:item.maxRange]];
	cell.falloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Falloff: %@ m", nil),
							  [NSNumberFormatter neocomLocalizedStringFromInteger:item.falloff]];
	cell.capacitorLabel.text = item.flags & NeocomAPIFlagCapStable ? NSLocalizedString(@"Capacitor is Stable", nil) : NSLocalizedString(@"Capacitor is Unstable", nil);
}


- (NSTimeInterval) defaultCacheExpireTime {
	return 60 * 60 * 24;
}


@end

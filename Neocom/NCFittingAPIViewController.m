//
//  NCFittingAPIViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAPIViewController.h"
#import "NCTableViewCell.h"
#import "NeocomAPI.h"

@interface NCFittingAPIViewController ()
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, assign) NeocomAPIFlag flags;

- (IBAction)onClear:(id)sender;
- (IBAction)onSwitch:(id)sender;
- (void) update;
@end

@implementation NCFittingAPIViewController

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
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 5 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	if (indexPath.section == 0) {
		if (indexPath.row < 4) {
			UIButton* clearButton = [[UIButton alloc] initWithFrame:CGRectZero];
			[clearButton setTitle:NSLocalizedString(@"Clear", nil) forState:UIControlStateNormal];
			clearButton.titleLabel.font = [UIFont systemFontOfSize:12];
			clearButton.titleLabel.textColor = [UIColor whiteColor];
			[clearButton addTarget:self action:@selector(onClear:) forControlEvents:UIControlEventTouchUpInside];
			
			if (indexPath.row == 0) {
				cell.textLabel.text = NSLocalizedString(@"Ship", nil);
				if (!self.type) {
					cell.detailTextLabel.text = NSLocalizedString(@"Any Ship", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
					cell.accessoryView = nil;
				}
				else {
					cell.detailTextLabel.text = self.type.typeName;
					cell.imageView.image = [UIImage imageNamed:[self.type typeSmallImageName]];
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 1) {
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
				cell.textLabel.text = NSLocalizedString(@"Ship Class", nil);
				if (!self.group) {
					cell.detailTextLabel.text = NSLocalizedString(@"Any Ship Class", nil);
					cell.accessoryView = nil;
				}
				else {
					cell.detailTextLabel.text = self.group.groupName;
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 2) {
				cell.textLabel.text = NSLocalizedString(@"Weapon Type", nil);
				if (self.flags & NeocomAPIFlagHybridTurrets) {
					cell.detailTextLabel.text = NSLocalizedString(@"Hybrid Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_06.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagLaserTurrets) {
					cell.detailTextLabel.text = NSLocalizedString(@"Energy Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_10.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagProjectileTurrets) {
					cell.detailTextLabel.text = NSLocalizedString(@"Projectile Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon12_14.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagMissileLaunchers) {
					cell.detailTextLabel.text = NSLocalizedString(@"Missile Launcher", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon12_12.png"];
					cell.accessoryView = clearButton;
				}
				else {
					cell.detailTextLabel.text = NSLocalizedString(@"Any Weapon Type", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_03.png"];
					cell.accessoryView = nil;
				}
			}
			else if (indexPath.row == 3) {
				cell.textLabel.text = NSLocalizedString(@"Type of Tanking", nil);
				if (self.flags & NeocomAPIFlagActiveTank) {
					if (self.flags & NeocomAPIFlagArmorTank) {
						cell.detailTextLabel.text = NSLocalizedString(@"Active Armor", nil);
						cell.imageView.image = [UIImage imageNamed:@"armorRepairer.png"];
						cell.accessoryView = clearButton;
					}
					else {
						cell.detailTextLabel.text = NSLocalizedString(@"Active Shield", nil);
						cell.imageView.image = [UIImage imageNamed:@"shieldBooster.png"];
						cell.accessoryView = clearButton;
					}
				}
				else if (self.flags & NeocomAPIFlagPassiveTank) {
					cell.detailTextLabel.text = NSLocalizedString(@"Passive", nil);
					cell.imageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
					cell.accessoryView = clearButton;
				}
				else {
					cell.detailTextLabel.text = NSLocalizedString(@"Any Type of Tanking", nil);
					cell.imageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
					cell.accessoryView = nil;
				}
			}
		}
		else {
			if (indexPath.row == 4) {
				cell.textLabel.text = NSLocalizedString(@"Only Cap Stable Fits", nil);
				cell.detailTextLabel.text = nil;
				cell.imageView.image = [UIImage imageNamed:@"capacitor.png"];
				UISwitch* switchView = [[UISwitch alloc] init];
				switchView.on = (self.flags & NeocomAPIFlagCapStable) == NeocomAPIFlagCapStable;
				[switchView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
				cell.accessoryView = switchView;
			}
		}
	}
	else {
		
	}
	return cell;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - Private

- (IBAction)onClear:(id)sender {
	UITableViewCell* cell = nil;
	for (cell = (UITableViewCell*) [sender superview]; ![cell isKindOfClass:[UITableViewCell class]] && cell; cell = (UITableViewCell*) cell.superview);
	
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	
	if (indexPath.row == 0)
		self.type = nil;
	else if (indexPath.row == 1)
		self.group = nil;
	else if (indexPath.row == 2)
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers));
	else if (indexPath.row == 3)
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank));
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self update];
}

- (IBAction)onSwitch:(id)sender {
	if ([sender isOn])
		self.flags |= NeocomAPIFlagCapStable;
	else
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagCapStable));
	[self update];
}

- (void) update {
	
}

@end

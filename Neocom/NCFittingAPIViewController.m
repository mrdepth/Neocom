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
#import "NCDatabaseTypePickerViewController.h"
#import "NCDatabaseGroupPickerViewContoller.h"
#import "NCFittingAPIFlagsViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingAPISearchResultsViewController.h"

@interface NCFittingAPIViewController ()
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, assign) NeocomAPIFlag flags;
@property (nonatomic, strong) NSDictionary* criteria;

@property (nonatomic, strong) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) NAPILookup* lookup;


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
	self.flags = NeocomAPIFlagComplete | NeocomAPIFlagValid;
	self.refreshControl = nil;
	[self update];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCFittingAPISearchResultsViewController"])
		return self.lookup.count > 0;
	else
		return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingAPIFlagsViewController"]) {
		NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
		NCFittingAPIFlagsViewController* destinationViewController = segue.destinationViewController;
		
		if (indexPath.row == 2) {
			destinationViewController.title = NSLocalizedString(@"Weapon Type", nil);
			destinationViewController.titles = @[NSLocalizedString(@"Hybrid Weapon", nil),
												 NSLocalizedString(@"Energy Weapon", nil),
												 NSLocalizedString(@"Projectile Weapon", nil),
												 NSLocalizedString(@"Missile Launcher", nil)];
			
			destinationViewController.values = @[@(NeocomAPIFlagHybridTurrets), @(NeocomAPIFlagLaserTurrets), @(NeocomAPIFlagProjectileTurrets), @(NeocomAPIFlagMissileLaunchers)];
			destinationViewController.icons = @[@"Icons/icon13_06.png", @"Icons/icon13_10.png", @"Icons/icon12_14.png", @"Icons/icon12_12.png"];
			destinationViewController.selectedValue = @(self.flags & (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers));
		}
		else {
			destinationViewController.title = NSLocalizedString(@"Type of Tanking", nil);
			destinationViewController.titles = @[NSLocalizedString(@"Active Armor", nil), NSLocalizedString(@"Active Shield", nil), NSLocalizedString(@"Passive", nil)];
			
			destinationViewController.values = @[@(NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank),
												 @(NeocomAPIFlagActiveTank | NeocomAPIFlagShieldTank),
												 @(NeocomAPIFlagPassiveTank)];
			
			destinationViewController.icons = @[@"armorRepairer.png", @"shieldBooster.png", @"shieldRecharge.png"];
			destinationViewController.selectedValue = @(self.flags & (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank));
		}
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseGroupPickerViewContoller"]) {
		NCDatabaseGroupPickerViewContoller* destinationViewController = segue.destinationViewController;
		destinationViewController.categoryID = NCShipCategoryID;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAPISearchResultsViewController"]) {
		NCFittingAPISearchResultsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.criteria = self.criteria;
	}
	
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
	if (indexPath.section == 0) {
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if (indexPath.row < 4) {
			UIButton* clearButton = [[UIButton alloc] initWithFrame:CGRectZero];
			[clearButton setTitle:NSLocalizedString(@"Clear", nil) forState:UIControlStateNormal];
			clearButton.titleLabel.font = [UIFont systemFontOfSize:15];
			clearButton.titleLabel.textColor = [UIColor whiteColor];
			[clearButton sizeToFit];
			[clearButton addTarget:self action:@selector(onClear:) forControlEvents:UIControlEventTouchUpInside];
			
			if (indexPath.row == 0) {
				cell.detailTextLabel.text = NSLocalizedString(@"Ship", nil);
				if (!self.type) {
					cell.textLabel.text = NSLocalizedString(@"Any Ship", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
					cell.accessoryView = nil;
				}
				else {
					cell.textLabel.text = self.type.typeName;
					cell.imageView.image = [UIImage imageNamed:[self.type typeSmallImageName]];
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 1) {
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
				cell.detailTextLabel.text = NSLocalizedString(@"Ship Class", nil);
				if (!self.group) {
					cell.textLabel.text = NSLocalizedString(@"Any Ship Class", nil);
					cell.accessoryView = nil;
				}
				else {
					cell.textLabel.text = self.group.groupName;
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 2) {
				cell.detailTextLabel.text = NSLocalizedString(@"Weapon Type", nil);
				if (self.flags & NeocomAPIFlagHybridTurrets) {
					cell.textLabel.text = NSLocalizedString(@"Hybrid Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_06.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagLaserTurrets) {
					cell.textLabel.text = NSLocalizedString(@"Energy Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_10.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagProjectileTurrets) {
					cell.textLabel.text = NSLocalizedString(@"Projectile Weapon", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon12_14.png"];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagMissileLaunchers) {
					cell.textLabel.text = NSLocalizedString(@"Missile Launcher", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon12_12.png"];
					cell.accessoryView = clearButton;
				}
				else {
					cell.textLabel.text = NSLocalizedString(@"Any Weapon Type", nil);
					cell.imageView.image = [UIImage imageNamed:@"Icons/icon13_03.png"];
					cell.accessoryView = nil;
				}
			}
			else if (indexPath.row == 3) {
				cell.detailTextLabel.text = NSLocalizedString(@"Type of Tanking", nil);
				if (self.flags & NeocomAPIFlagActiveTank) {
					if (self.flags & NeocomAPIFlagArmorTank) {
						cell.textLabel.text = NSLocalizedString(@"Active Armor", nil);
						cell.imageView.image = [UIImage imageNamed:@"armorRepairer.png"];
						cell.accessoryView = clearButton;
					}
					else {
						cell.textLabel.text = NSLocalizedString(@"Active Shield", nil);
						cell.imageView.image = [UIImage imageNamed:@"shieldBooster.png"];
						cell.accessoryView = clearButton;
					}
				}
				else if (self.flags & NeocomAPIFlagPassiveTank) {
					cell.textLabel.text = NSLocalizedString(@"Passive", nil);
					cell.imageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
					cell.accessoryView = clearButton;
				}
				else {
					cell.textLabel.text = NSLocalizedString(@"Any Type of Tanking", nil);
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
		return cell;
	}
	else {
		NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultsCell" forIndexPath:indexPath];
		if (self.lookup.count > 0) {
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ loadouts", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.lookup.count]];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			cell.textLabel.text = NSLocalizedString(@"No Results", nil);
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		return cell;
	}
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
			[self.typePickerViewController presentWithConditions:@[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"]
												inViewController:self
														fromRect:cell.bounds
														  inView:cell
														animated:YES
											   completionHandler:^(EVEDBInvType *type) {
												   self.type = type;
												   [self dismissAnimated];
												   [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
												   [self update];
											   }];
		}
		else if (indexPath.row == 1) {
			[self performSegueWithIdentifier:@"NCDatabaseGroupPickerViewContoller" sender:cell];
		}
		else if (indexPath.row == 2 || indexPath.row == 3) {
			[self performSegueWithIdentifier:@"NCFittingAPIFlagsViewController" sender:cell];
		}
	}
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - Unwind

- (IBAction)unwindFromGroupPicker:(UIStoryboardSegue*) segue {
	NCDatabaseGroupPickerViewContoller* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedGroup) {
		self.group = sourceViewController.selectedGroup;
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		[self update];
	}
}

- (IBAction)unwindFromAPIFlags:(UIStoryboardSegue*) segue {
	NCFittingAPIFlagsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedValue) {
		NSInteger flags = 0;
		for (NSNumber* flag in sourceViewController.values)
			flags |= [flag integerValue];
		self.flags = (self.flags & (-1 ^ flags)) | [sourceViewController.selectedValue integerValue];
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0], [NSIndexPath indexPathForRow:3 inSection:0]]  withRowAnimation:UITableViewRowAnimationFade];
		[self update];
	}

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
	NSMutableDictionary* criteria = [NSMutableDictionary dictionary];
	if (self.type)
		criteria[@"typeID"] = @(self.type.typeID);
	else if (self.group)
		criteria[@"groupID"] = @(self.group.groupID);
	if (self.flags)
		criteria[@"flags"] = @(self.flags);
	
	self.criteria = criteria;

	__block NAPILookup* lookup = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 lookup = [NAPILookup lookupWithCriteria:criteria cachePolicy:NSURLRequestUseProtocolCachePolicy error:nil progressHandler:^(CGFloat progress, BOOL *stop) {
												 task.progress = progress;
											 }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled] && lookup) {
									 self.lookup = lookup;
									 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
								 }
							 }];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

@end

//
//  NAPISearchViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import "NAPISearchViewController.h"
#import "UITableViewCell+Nib.h"
#import "EVEDBAPI.h"
#import "NAPIValuesViewController.h"
#import "NeocomAPI.h"
#import "EUOperationQueue.h"
#import "NAPISearchResultsViewController.h"
#import "ShipFit.h"
#import "UIAlertView+Block.h"
#import "Globals.h"
#import "UIViewController+Neocom.h"
#import "GroupedCell.h"
#import "appearance.h"
#import "RoundRectButton.h"
#import "NSString+TimeLeft.h"
#import "UIActionSheet+Block.h"

@interface NAPISearchViewController ()
@property (nonatomic, strong) EVEDBInvType* ship;
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, assign) NSInteger flags;
@property (nonatomic, strong) NSDictionary* criteria;
@property (nonatomic, strong) UIActionSheet* actionSheet;

- (void) update;
- (void) uploadFits;
- (IBAction)onClear:(id)sender;
- (IBAction)onSwitch:(UISwitch*)switchView;
@end

@implementation NAPISearchViewController

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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	self.flags = NeocomAPIFlagComplete | NeocomAPIFlagValid;
	self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearch:)],
												[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]];
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	self.title = NSLocalizedString(@"Community Fits", nil);
	[self update];
	
	NSDate* date = [[NSUserDefaults standardUserDefaults] valueForKey:SettingsNeocomAPINextSyncDate];
	if (!date || [date earlierDate:[NSDate date]] == date) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:SettingsNeocomAPIAlwaysUploadFits])
			[self uploadFits];
		else {
			[[UIAlertView alertViewWithTitle:nil
									 message:NSLocalizedString(@"Would you like to make your contribution to the Neocom community by sharing your fit?", nil)
						   cancelButtonTitle:NSLocalizedString(@"Don't share this time", nil)
						   otherButtonTitles:@[NSLocalizedString(@"Share this time", nil), NSLocalizedString(@"Always share", nil)]
							 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
								 if (selectedButtonIndex == 2)
									 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SettingsNeocomAPIAlwaysUploadFits];
								 if (selectedButtonIndex != alertView.cancelButtonIndex)
									 [self uploadFits];
								 else {
									 [[NSUserDefaults standardUserDefaults] setValue:[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 6] forKey:SettingsNeocomAPINextSyncDate];
								 }
							 } cancelBlock:^{
							 }] show];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSearch:(id)sender {
	NAPISearchResultsViewController* controller = [[NAPISearchResultsViewController alloc] initWithNibName:@"NAPISearchResultsViewController" bundle:nil];
	controller.criteria = self.criteria;
	[self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)onAction:(id)sender {
	NSDate* nextSyncDate = [[NSUserDefaults standardUserDefaults] valueForKey:SettingsNeocomAPINextSyncDate];
	BOOL alwaysUpload =[[NSUserDefaults standardUserDefaults] boolForKey:SettingsNeocomAPIAlwaysUploadFits];
	NSString* title = nil;
	if (nextSyncDate) {
		NSInteger timeInterval = [nextSyncDate timeIntervalSinceNow];
		if (timeInterval > 0)
			title = [NSString stringWithFormat:@"Next sync in %@", [NSString stringWithTimeLeft:timeInterval]];
	}
	[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:NO];
	
	self.actionSheet = [UIActionSheet actionSheetWithTitle:title
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:@[NSLocalizedString(@"Sync now", nil), alwaysUpload ? NSLocalizedString(@"Disable auto sync", nil) : NSLocalizedString(@"Enable auto sync", nil)]
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex == 0)
												   [self uploadFits];
											   else if (selectedButtonIndex == 1) {
												   [[NSUserDefaults standardUserDefaults] setBool:!alwaysUpload forKey:SettingsNeocomAPIAlwaysUploadFits];
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 5;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	
	GroupedCell* cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
	}
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	
	UIButton* clearButton = [[RoundRectButton alloc] initWithFrame:CGRectMake(0, 0, 64, 30)];
	[clearButton setTitle:NSLocalizedString(@"Clear", nil) forState:UIControlStateNormal];
	clearButton.titleLabel.font = [UIFont systemFontOfSize:12];
	clearButton.titleLabel.textColor = [UIColor whiteColor];
	[clearButton addTarget:self action:@selector(onClear:) forControlEvents:UIControlEventTouchUpInside];

    if (indexPath.row < 4) {
		if (indexPath.row == 0) {
			cell.textLabel.text = NSLocalizedString(@"Ship", nil);
			if (!self.ship) {
				cell.detailTextLabel.text = NSLocalizedString(@"Any Ship", nil);
				cell.imageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
				cell.accessoryView = nil;
			}
			else {
				cell.detailTextLabel.text = self.ship.typeName;
				cell.imageView.image = [UIImage imageNamed:[self.ship typeSmallImageName]];
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
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 0) {
		NCItemsViewController* controller = [[NCItemsViewController alloc] init];
		
		controller.title = NSLocalizedString(@"Ships", nil);
		controller.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"];
		
		
		controller.completionHandler = ^(EVEDBInvType* type) {
			self.ship = type;
			self.group = nil;
			[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
			
			[self update];
			[self dismiss];
		};
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self presentViewControllerInPopover:controller
										fromRect:[tableView rectForRowAtIndexPath:indexPath]
										  inView:tableView
						permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else {
			[self presentViewController:controller animated:YES completion:nil];
		}
	}
	else if (indexPath.row == 1) {
		KillNetFilterShipClassesViewController* controller = [[KillNetFilterShipClassesViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
		controller.delegate = self;
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self presentViewControllerInPopover:navigationController
										fromRect:[tableView rectForRowAtIndexPath:indexPath]
										  inView:tableView
						permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
			[self presentViewController:navigationController animated:YES completion:nil];
		}
	}
	else if (indexPath.row == 2 || indexPath.row == 3) {
		NAPIValuesViewController* controller = [[NAPIValuesViewController alloc] initWithNibName:@"NAPIValuesViewController" bundle:nil];
		
		if (indexPath.row == 2) {
			controller.title = NSLocalizedString(@"Weapon Type", nil);
			controller.titles = @[NSLocalizedString(@"Hybrid Weapon", nil), NSLocalizedString(@"Energy Weapon", nil), NSLocalizedString(@"Projectile Weapon", nil), NSLocalizedString(@"Missile Launcher", nil)];
			controller.values = @[@(NeocomAPIFlagHybridTurrets), @(NeocomAPIFlagLaserTurrets), @(NeocomAPIFlagProjectileTurrets), @(NeocomAPIFlagMissileLaunchers)];
			controller.icons = @[@"Icons/icon13_06.png", @"Icons/icon13_10.png", @"Icons/icon12_14.png", @"Icons/icon12_12.png"];
			controller.selectedValue = @(self.flags & (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers));
		}
		else {
			controller.title = NSLocalizedString(@"Type of Tanking", nil);
			controller.titles = @[NSLocalizedString(@"Active Armor", nil), NSLocalizedString(@"Active Shield", nil), NSLocalizedString(@"Passive", nil)];
			controller.values = @[@(NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank), @(NeocomAPIFlagActiveTank | NeocomAPIFlagShieldTank), @(NeocomAPIFlagPassiveTank)];
			controller.icons = @[@"armorRepairer.png", @"shieldBooster.png", @"shieldRecharge.png"];
			controller.selectedValue = @(self.flags & (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank));
		}
		
		
		__weak NAPISearchViewController* weakSelf = self;
		controller.completionHandler = ^(NSValue* value) {
			
			if (indexPath.row == 2)
				weakSelf.flags = (weakSelf.flags & (-1 ^ (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers))) | [(NSNumber*) value integerValue];
			else
				weakSelf.flags = (weakSelf.flags & (-1 ^ (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank))) | [(NSNumber*) value integerValue];
			
			[weakSelf dismiss];
			[weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[weakSelf update];
		};
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self presentViewControllerInPopover:navigationController
										fromRect:[tableView rectForRowAtIndexPath:indexPath]
										  inView:tableView
						permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
			[self presentViewController:navigationController animated:YES completion:nil];
		}
	}
	return;
}

#pragma mark - KillNetFilterDBViewControllerDelegate

- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item {
	self.ship = nil;
	self.group = [EVEDBInvGroup invGroupWithGroupID:[item[@"itemID"] integerValue] error:nil];
	[self dismiss];
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	[self update];
}

#pragma mark - Private

- (void) update {
	NSMutableDictionary* criteria = [NSMutableDictionary dictionary];
	if (self.ship)
		[criteria setValue:[NSString stringWithFormat:@"%d", self.ship.typeID] forKey:@"typeID"];
	else if (self.group)
		[criteria setValue:[NSString stringWithFormat:@"%d", self.group.groupID] forKey:@"groupID"];
	if (self.flags)
		[criteria setValue:[NSString stringWithFormat:@"%d", self.flags] forKey:@"flags"];
	self.criteria = criteria;
	
	__block NSInteger count = 0;
	EUOperation *operation = [EUOperation operationWithIdentifier:@"NAPISearchViewController+Lookup" name:nil];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NAPILookup* lookup = [NAPILookup lookupWithCriteria:criteria error:nil progressHandler:nil];
		count = lookup.count;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.fitsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d loadouts", nil), count];
			self.navigationItem.rightBarButtonItem.enabled = count > 0;
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (void) uploadFits {
	EUOperation* operation = [EUOperation operationWithIdentifier:@"FittingServiceMenuViewController+Load" name:NSLocalizedString(@"Loading Fits", nil)];
	__weak EUOperation* weakOperation = operation;
	__block NSError* error = nil;
	
	[operation addExecutionBlock:^{
		NSMutableArray* canonicalNames = [[NSMutableArray alloc] init];
		for (ShipFit* fit in [ShipFit allFits]) {
			[canonicalNames addObject:[fit canonicalName]];
		}
		if (canonicalNames.count > 0)
			[NAPIUpload uploadFitsWithCannonicalNames:canonicalNames userID:[[NSUserDefaults standardUserDefaults] valueForKey:SettingsUDID]
												error:&error
									  progressHandler:nil];
	}];
	
	[operation setCompletionBlockInMainThread:^{
		if (![weakOperation isCancelled] && !error) {
			[[NSUserDefaults standardUserDefaults] setValue:[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24] forKey:SettingsNeocomAPINextSyncDate];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

- (IBAction)onClear:(id)sender {
	UITableViewCell* cell = nil;
	for (cell = (UITableViewCell*) [sender superview]; ![cell isKindOfClass:[UITableViewCell class]] && cell; cell = (UITableViewCell*) cell.superview);

	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	
	if (indexPath.row == 0)
		self.ship = nil;
	else if (indexPath.row == 1)
		self.group = nil;
	else if (indexPath.row == 2)
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers));
	else if (indexPath.row == 3)
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank));
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self update];
}

- (IBAction)onSwitch:(UISwitch*)switchView {
	if (switchView.on)
		self.flags |= NeocomAPIFlagCapStable;
	else
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagCapStable));
	[self update];
}

@end

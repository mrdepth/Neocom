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

@interface NAPISearchViewController ()
@property (nonatomic, strong) EVEDBInvType* ship;
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, strong) UIPopoverController* popoverController;
@property (nonatomic, assign) NSInteger flags;
@property (nonatomic, strong) NSDictionary* criteria;

- (void) update;
- (void) uploadFits;
@end

@implementation NAPISearchViewController
@synthesize popoverController;

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background3.png"]];
	else {
		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background1.png"]];
		self.tableView.backgroundView.contentMode = UIViewContentModeTop;
	}

	self.flags = NeocomAPIFlagComplete | NeocomAPIFlagValid;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearch:)];
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	self.title = NSLocalizedString(@"Community Fits", nil);
	self.fittingItemsViewController.marketGroupID = 4;
	self.fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
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
								 NSLog(@"%d", selectedButtonIndex);
							 } cancelBlock:^{
							 }] show];
		}
	}
}

- (void)viewDidUnload {
	self.fittingItemsViewController = nil;
	self.fittingItemsNavigationController = nil;
	[self setShipClassesViewController:nil];
	[self setShipClassesNavigationController:nil];
	[self setFitsCountLabel:nil];
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onSearch:(id)sender {
	NAPISearchResultsViewController* controller = [[NAPISearchResultsViewController alloc] initWithNibName:@"NAPISearchResultsViewController" bundle:nil];
	controller.criteria = self.criteria;
	[self.navigationController pushViewController:controller animated:YES];
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
    if (indexPath.row < 4) {
		NSString *cellIdentifier = @"NAPISearchTitleCellView";
		
		NAPISearchTitleCellView *cell = (NAPISearchTitleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [NAPISearchTitleCellView cellWithNibName:@"NAPISearchTitleCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.delegate = self;
		}
		cell.accessoryType = UITableViewCellAccessoryNone;
		if (indexPath.row == 0) {
			if (!self.ship) {
				cell.titleLabel.text = NSLocalizedString(@"Any Ship", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
				cell.clearButton.hidden = YES;
			}
			else {
				cell.titleLabel.text = self.ship.typeName;
				cell.iconImageView.image = [UIImage imageNamed:[self.ship typeSmallImageName]];
				cell.clearButton.hidden = NO;
			}
		}
		else if (indexPath.row == 1) {
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
			if (!self.group) {
				cell.titleLabel.text = NSLocalizedString(@"Any Ship Class", nil);
				cell.clearButton.hidden = YES;
			}
			else {
				cell.titleLabel.text = self.group.groupName;
				cell.clearButton.hidden = NO;
			}
		}
		else if (indexPath.row == 2) {
			if (self.flags & NeocomAPIFlagHybridTurrets) {
				cell.titleLabel.text = NSLocalizedString(@"Hybrid Weapon", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon13_06.png"];
				cell.clearButton.hidden = NO;
			}
			else if (self.flags & NeocomAPIFlagLaserTurrets) {
				cell.titleLabel.text = NSLocalizedString(@"Energy Weapon", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon13_10.png"];
				cell.clearButton.hidden = NO;
			}
			else if (self.flags & NeocomAPIFlagProjectileTurrets) {
				cell.titleLabel.text = NSLocalizedString(@"Projectile Weapon", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon12_14.png"];
				cell.clearButton.hidden = NO;
			}
			else if (self.flags & NeocomAPIFlagMissileLaunchers) {
				cell.titleLabel.text = NSLocalizedString(@"Missile Launcher", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon04_01.png"];
				cell.clearButton.hidden = NO;
			}
			else {
				cell.clearButton.hidden = YES;
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon13_03.png"];
				cell.titleLabel.text = NSLocalizedString(@"Any Weapon Type", nil);
			}
		}
		else if (indexPath.row == 3) {
			if (self.flags & NeocomAPIFlagActiveTank) {
				if (self.flags & NeocomAPIFlagArmorTank) {
					cell.titleLabel.text = NSLocalizedString(@"Active Armor", nil);
					cell.iconImageView.image = [UIImage imageNamed:@"armorRepairer.png"];
					cell.clearButton.hidden = NO;
				}
				else {
					cell.titleLabel.text = NSLocalizedString(@"Active Shield", nil);
					cell.iconImageView.image = [UIImage imageNamed:@"shieldBooster.png"];
					cell.clearButton.hidden = NO;
				}
			}
			else if (self.flags & NeocomAPIFlagPassiveTank) {
				cell.titleLabel.text = NSLocalizedString(@"Passive", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
				cell.clearButton.hidden = NO;
			}
			else {
				cell.titleLabel.text = NSLocalizedString(@"Any Type of Tanking", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"shieldRecharge.png"];
				cell.clearButton.hidden = YES;
			}
		}
		return cell;
	}
	else {
		NSString *cellIdentifier = @"NAPISearchSwitchCellView";
		
		NAPISearchSwitchCellView *cell = (NAPISearchSwitchCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [NAPISearchSwitchCellView cellWithNibName:@"NAPISearchSwitchCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.delegate = self;
		}
		if (indexPath.row == 4) {
			cell.titleLabel.text = NSLocalizedString(@"Only Cap Stable Fits", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"capacitor.png"];
			cell.switchView.on = (self.flags & NeocomAPIFlagCapStable) == NeocomAPIFlagCapStable;
		}
		return cell;
	}
	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 0) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.fittingItemsNavigationController];
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			[self presentModalViewController:self.fittingItemsNavigationController animated:YES];
		}
	}
	else if (indexPath.row == 1) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.shipClassesNavigationController];
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			[self presentModalViewController:self.shipClassesNavigationController animated:YES];
		}
	}
	else if (indexPath.row == 2 || indexPath.row == 3) {
		NAPIValuesViewController* controller = [[NAPIValuesViewController alloc] initWithNibName:@"NAPIValuesViewController" bundle:nil];
		
		if (indexPath.row == 2) {
			controller.title = NSLocalizedString(@"Weapon Type", nil);
			controller.titles = @[NSLocalizedString(@"Hybrid Weapon", nil), NSLocalizedString(@"Energy Weapon", nil), NSLocalizedString(@"Projectile Weapon", nil), NSLocalizedString(@"Missile Launcher", nil)];
			controller.values = @[@(NeocomAPIFlagHybridTurrets), @(NeocomAPIFlagLaserTurrets), @(NeocomAPIFlagProjectileTurrets), @(NeocomAPIFlagMissileLaunchers)];
			controller.icons = @[@"Icons/icon13_06.png", @"Icons/icon13_10.png", @"Icons/icon12_14.png", @"Icons/icon04_01.png"];
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
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[weakSelf.popoverController dismissPopoverAnimated:YES];
			else
				[weakSelf dismissModalViewControllerAnimated:YES];
			[weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[weakSelf update];
		};
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
																						   style:UIBarButtonItemStyleBordered
																						  target:self action:@selector(onClose:)];
			[self presentModalViewController:navigationController animated:YES];
		}
	}	
	return;
}

#pragma mark - FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	self.ship = type;
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
	[self update];
}

#pragma mark - KillNetFilterDBViewControllerDelegate

- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item {
	self.ship = nil;
	self.group = [EVEDBInvGroup invGroupWithGroupID:[item[@"itemID"] integerValue] error:nil];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	[self update];
}

#pragma mark - NAPISearchTitleCellViewDelegate

- (void) searchTitleCellViewDidClear:(NAPISearchTitleCellView*) cellView {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cellView];
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

#pragma mark - NAPISearchSwitchCellViewDelegate

- (void) switchCellViewDidSwitch:(NAPISearchSwitchCellView*) cellView{
	if (cellView.switchView.on)
		self.flags |= NeocomAPIFlagCapStable;
	else
		self.flags = self.flags & (-1 ^ (NeocomAPIFlagCapStable));
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
	
	[operation setCompletionBlockInCurrentThread:^(void) {
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
	
	[operation setCompletionBlockInCurrentThread:^{
		if (![weakOperation isCancelled] && !error) {
			[[NSUserDefaults standardUserDefaults] setValue:[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24] forKey:SettingsNeocomAPINextSyncDate];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end

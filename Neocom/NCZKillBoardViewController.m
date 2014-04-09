//
//  NCZKillBoardViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCZKillBoardViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCDatabaseGroupPickerViewContoller.h"
#import "NCDatabaseSolarSystemPickerViewController.h"
#import "UIAlertView+Block.h"
#import "NCCharacterID.h"
#import "NCZKillBoardSearchResultsViewController.h"
#import "EVEzKillBoardAPI.h"
#import "NCTableViewCell.h"
#import "NCZKillBoardSwitchCell.h"

typedef NS_ENUM(NSInteger, NCZKillBoardViewControllerFilter) {
	NCZKillBoardViewControllerFilterAll,
	NCZKillBoardViewControllerFilterKills,
	NCZKillBoardViewControllerFilterLosses
};

@interface NCZKillBoardViewController ()
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVEDBMapSolarSystem* solarSystem;
@property (nonatomic, strong) EVEDBMapRegion* region;
@property (nonatomic, strong) NCCharacterID* characterID;
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, assign) NCZKillBoardViewControllerFilter filter;
@property (nonatomic, assign) BOOL soloKills;
@property (nonatomic, assign) BOOL whKills;

@property (nonatomic, strong) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong) NSMutableArray* cellIdentifiers;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@property (nonatomic, assign) BOOL searchingCharacterName;

- (void) showCharacterNameDialogWithName:(NSString*) name message:(NSString*) message;
@end

@implementation NCZKillBoardViewController

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
	self.dateFormatter = [NSDateFormatter new];
	[self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];

	
	self.cellIdentifiers = [NSMutableArray new];
	[self.cellIdentifiers addObject:@"ShipCell"];
	[self.cellIdentifiers addObject:@"ShipClassCell"];
	[self.cellIdentifiers addObject:@"CharacterCell"];
	[self.cellIdentifiers addObject:@"SolarSystemCell"];
	[self.cellIdentifiers addObject:@"KillsCell"];
	[self.cellIdentifiers addObject:@"WHCell"];
	[self.cellIdentifiers addObject:@"SoloKillsCell"];
	[self.cellIdentifiers addObject:@"DateCell"];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCDatabaseGroupPickerViewContoller"]) {
		NCDatabaseGroupPickerViewContoller* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.categoryID = NCShipCategoryID;
	}
	else if ([segue.identifier isEqualToString:@"NCZKillBoardSearchResultsViewController"]) {
		NCZKillBoardSearchResultsViewController* destinationViewController = segue.destinationViewController;
		NSMutableDictionary* filter = [NSMutableDictionary new];
		filter[EVEzKillBoardSearchFilterOrderDirectionKey] = EVEzKillBoardSearchFilterOrderDirectionDescending;
		if (self.group)
			filter[EVEzKillBoardSearchFilterGroupIDKey] = @(self.group.groupID);
		if (self.type)
			filter[EVEzKillBoardSearchFilterShipTypeIDKey] = @(self.type.typeID);
		if (self.solarSystem)
			filter[EVEzKillBoardSearchFilterSolarSystemIDKey] = @(self.solarSystem.solarSystemID);
		if (self.region)
			filter[EVEzKillBoardSearchFilterRegionIDKey] = @(self.region.regionID);
		
		if (self.characterID) {
			if (self.characterID.type == NCCharacterIDTypeCharacter)
				filter[EVEzKillBoardSearchFilterCharacterIDKey] = @(self.characterID.characterID);
			else if (self.characterID.type == NCCharacterIDTypeCorporation)
				filter[EVEzKillBoardSearchFilterCorporationIDKey] = @(self.characterID.characterID);
			else if (self.characterID.type == NCCharacterIDTypeAlliance)
				filter[EVEzKillBoardSearchFilterAllianceIDKey] = @(self.characterID.characterID);
		}
		
		if (self.filter == NCZKillBoardViewControllerFilterKills)
			filter[EVEzKillBoardSearchFilterKillsKey] = @"";
		else if (self.filter == NCZKillBoardViewControllerFilterLosses)
			filter[EVEzKillBoardSearchFilterLossesKey] = @"";
		
		if (self.whKills)
			filter[EVEzKillBoardSearchFilterWSpaceKey] = @"";
		
		if (self.soloKills)
			filter[EVEzKillBoardSearchFilterSoloKey] = @"";
		
		if (self.date) {
			NSDateFormatter* dateFormatter = [NSDateFormatter new];
			[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
			[dateFormatter setDateFormat:@"yyyyMMdd'T'HHmmss"];
			filter[EVEzKillBoardSearchFilterStartTimeKey] = [dateFormatter stringFromDate:self.date];
		}
		destinationViewController.filter = filter;
	}
}

- (IBAction)onChangeDate:(UIDatePicker*)sender {
	self.date = sender.date;
	NCTableViewCell* cell = (NCTableViewCell*) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]];
	if (cell)
		cell.titleLabel.text = [NSString stringWithFormat:@"Since %@", [self.dateFormatter stringFromDate:self.date]];
}

- (IBAction)onChangeFilter:(UISegmentedControl*)sender {
	self.filter = sender.selectedSegmentIndex;
}

- (IBAction)onChangeWHKills:(UISwitch*)sender {
	self.whKills = sender.on;
}

- (IBAction)onChangeSoloKills:(UISwitch*)sender {
	self.soloKills = sender.on;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellIdentifiers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* cellIdentifier = self.cellIdentifiers[indexPath.row];
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	static UIButton* (^newClearButton)() = nil;
	if (!newClearButton)
		newClearButton = ^() {
			UIButton* button = [[UIButton alloc] initWithFrame:CGRectZero];
			button.titleLabel.font = [UIFont systemFontOfSize:15];
			button.titleLabel.textColor = [UIColor whiteColor];
			[button setTitle:NSLocalizedString(@"Clear", nil) forState:UIControlStateNormal];
			[button sizeToFit];
			[button addTarget:self action:@selector(onClear:) forControlEvents:UIControlEventTouchUpInside];
			return button;
		};

	if ([cellIdentifier isEqualToString:@"ShipCell"]) {
		if (self.type) {
			cell.accessoryView = newClearButton();
			cell.titleLabel.text = self.type.typeName;
			cell.iconView.image = [UIImage imageNamed:self.type.typeSmallImageName];
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Any Ship", nil);
			cell.iconView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
			cell.accessoryView = nil;
		}
	}
	else if ([cellIdentifier isEqualToString:@"ShipClassCell"]) {
		if (self.group) {
			cell.accessoryView = newClearButton();
			cell.titleLabel.text = self.group.groupName;
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Any Ship Class", nil);
			cell.accessoryView = nil;
		}
		cell.iconView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
	}
	else if ([cellIdentifier isEqualToString:@"CharacterCell"]) {
		if (self.characterID) {
			cell.titleLabel.text = self.characterID.name;
			if (self.characterID.type == NCCharacterIDTypeCharacter)
				cell.subtitleLabel.text = NSLocalizedString(@"Character", nil);
			else if (self.characterID.type == NCCharacterIDTypeCorporation)
				cell.subtitleLabel.text = NSLocalizedString(@"Corporation", nil);
			else
				cell.subtitleLabel.text = NSLocalizedString(@"Alliance", nil);
			cell.accessoryView = newClearButton();
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Any Character", nil);
			cell.subtitleLabel.text = NSLocalizedString(@"Character, Corporation or Alliance", nil);
			cell.accessoryView = nil;

		}
	}
	else if ([cellIdentifier isEqualToString:@"SolarSystemCell"]) {
		if (self.solarSystem) {
			cell.titleLabel.text = self.solarSystem.solarSystemName;
			cell.accessoryView = newClearButton();
			cell.subtitleLabel.text = NSLocalizedString(@"Solar System", nil);
		}
		else if (self.region) {
			cell.titleLabel.text = self.region.regionName;
			cell.accessoryView = newClearButton();
			cell.subtitleLabel.text = NSLocalizedString(@"Region", nil);
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"Any Solar System", nil);
			cell.accessoryView = nil;
			cell.subtitleLabel.text = NSLocalizedString(@"Solar System or Region", nil);
		}
	}
	else if ([cellIdentifier isEqualToString:@"KillsCell"]) {
		UISegmentedControl* control = (UISegmentedControl*) [cell.contentView viewWithTag:1];
		control.selectedSegmentIndex = self.filter;
	}
	else if ([cellIdentifier isEqualToString:@"WHCell"]) {
//		cell.titleLabel.text = NSLocalizedString(@"Only WH Kills", nil);
		UISwitch* switchView = [(NCZKillBoardSwitchCell*) cell switchView];
		switchView.on = self.whKills;
	}
	else if ([cellIdentifier isEqualToString:@"SoloKillsCell"]) {
//		cell.titleLabel.text = NSLocalizedString(@"Only Solo Kills", nil);
		UISwitch* switchView = [(NCZKillBoardSwitchCell*) cell switchView];
		switchView.on = self.soloKills;
	}
	else if ([cellIdentifier isEqualToString:@"DateCell"]) {
		if (self.date) {
			cell.titleLabel.text = [NSString stringWithFormat:@"Since %@", [self.dateFormatter stringFromDate:self.date]];
			cell.accessoryView = newClearButton();
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"All Time", nil);
			cell.accessoryView = nil;
		}
	}
	else if ([cellIdentifier isEqualToString:@"DatePickerCell"]) {
		UIDatePicker* datePicker = (UIDatePicker*) [cell.contentView viewWithTag:1];
		datePicker.date = self.date;
		datePicker.maximumDate = [NSDate date];
	}
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 0) {
		UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
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
											   if (self.group) {
												   self.group = nil;
												   [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
											   }
										   }];

	}
	else if (indexPath.row == 2) {
		if (!self.searchingCharacterName)
			[self showCharacterNameDialogWithName:nil message:NSLocalizedString(@"Enter Character, Corporation or Alliance name", nil)];
	}
	else if (indexPath.row == 7) {
		NSInteger index = [self.cellIdentifiers indexOfObject:@"DatePickerCell"];
		if (index == NSNotFound) {
			if (!self.date)
				self.date = [NSDate date];
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			
			[self.cellIdentifiers addObject:@"DatePickerCell"];
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:8 inSection:0];
			[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		}
		else {
			[self.cellIdentifiers removeObjectAtIndex:index];
			[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:8 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	NSString* cellIdentifier = self.cellIdentifiers[indexPath.row];
	if ([cellIdentifier isEqualToString:@"DatePickerCell"])
		cell.backgroundColor = [UIColor whiteColor];
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

		if (self.type) {
			self.type = nil;
			[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}

	}
}

- (IBAction)unwindFromSolarSystemPicker:(UIStoryboardSegue*) segue {
	NCDatabaseSolarSystemPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedObject) {
		if ([sourceViewController.selectedObject isKindOfClass:[EVEDBMapRegion class]]) {
			self.region = sourceViewController.selectedObject;
			self.solarSystem = nil;
		}
		else {
			self.solarSystem = sourceViewController.selectedObject;
			self.region = nil;
		}
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Private

- (IBAction)onClear:(id)sender {
	id cell = [sender superview];
	for (;![cell isKindOfClass:[UITableViewCell class]]; cell = [cell superview]);
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	if (indexPath.row == 0) {
		self.type = nil;
	}
	else if (indexPath.row == 1) {
		self.group = nil;
	}
	else if (indexPath.row == 2) {
		self.characterID = nil;
	}
	else if (indexPath.row == 3) {
		self.region = nil;
		self.solarSystem = nil;
	}
	else if (indexPath.row == 7) {
		self.date = nil;
		NSInteger index = [self.cellIdentifiers indexOfObject:@"DatePickerCell"];
		if (index != NSNotFound) {
			[self.cellIdentifiers removeObjectAtIndex:index];
			[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}

	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (void) showCharacterNameDialogWithName:(NSString*) name message:(NSString*) message {
	UIAlertView* alertView = [UIAlertView alertViewWithTitle:nil
													 message:message
										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										   otherButtonTitles:@[NSLocalizedString(@"Ok", nil)]
											 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
												 if (selectedButtonIndex != alertView.cancelButtonIndex) {
													 UITextField* textField = [alertView textFieldAtIndex:0];
													 NSString* name = textField.text;
													 self.searchingCharacterName = YES;
													 UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
													 UIView* oldAccessory = cell.accessoryView;
													 if (cell) {
														 UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
														 [activityIndicatorView startAnimating];
														 cell.accessoryView = activityIndicatorView;
													 }
													 __block NCCharacterID* characterID = nil;
													 [[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
																						  title:NCTaskManagerDefaultTitle
																						  block:^(NCTask *task) {
																							  characterID = [NCCharacterID characterIDWithName:name];
																						  }
																			  completionHandler:^(NCTask *task) {
																				  self.searchingCharacterName = NO;
																				  if (characterID) {
																					  self.characterID = characterID;
																					  [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:2 inSection:0]]
																											withRowAnimation:UITableViewRowAnimationFade];
																				  }
																				  else
																					  [self showCharacterNameDialogWithName:name
																													message:NSLocalizedString(@"Unknown Character, Corporation or Alliance name", nil)];
																				  cell.accessoryView = oldAccessory;
																			  }];
												 }
											 } cancelBlock:nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField* textField = [alertView textFieldAtIndex:0];
	textField.placeholder = NSLocalizedString(@"Character/Corporation/Alliance name", nil);
	textField.text = name;
	textField.clearButtonMode = UITextFieldViewModeAlways;
	[alertView show];
}

@end

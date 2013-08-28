//
//  POSFittingViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "POSFittingViewController.h"
#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "POSFit.h"
#import "ItemInfo.h"
#import "DamagePattern.h"
#import "RequiredSkillsViewController.h"
#import "EVEDBAPI.h"
#import "PriceManager.h"
#import "appearance.h"
#import "UIActionSheet+Block.h"
#import "UIViewController+Neocom.h"

#include "eufe.h"

#define ActionButtonBack NSLocalizedString(@"Back", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonAreaEffect NSLocalizedString(@"Select Area Effect", nil)
#define ActionButtonClearAreaEffect NSLocalizedString(@"Clear Area Effect", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface POSFittingViewController()
@property(nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, readwrite) eufe::Engine* fittingEngine;
@property (nonatomic, strong, readwrite) NCItemsViewController* itemsViewController;

- (void) save;

@end

@implementation POSFittingViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];

	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)];
	
	self.fitNameTextField.text = self.fit.fitName;
	self.damagePattern = [DamagePattern uniformDamagePattern];
	
	self.priceManager = [[PriceManager alloc] init];
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onMenu:)]];
	[self update];
	self.tableView.tableHeaderView = self.structuresDataSource.tableHeaderView;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self save];
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc {
	delete self.fittingEngine;
}

- (IBAction) didChangeSection:(id) sender {
	POSFittingDataSource* dataSources[] = {self.structuresDataSource, self.assemblyLinesDataSource, self.statsDataSource};
	self.tableView.dataSource = dataSources[self.sectionSegmentControl.selectedSegmentIndex];
	self.tableView.delegate = dataSources[self.sectionSegmentControl.selectedSegmentIndex];
	self.tableView.tableHeaderView = dataSources[self.sectionSegmentControl.selectedSegmentIndex].tableHeaderView;
	[dataSources[self.sectionSegmentControl.selectedSegmentIndex] reload];
}

- (IBAction) onMenu:(id) sender {
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
	}
	NSMutableArray* buttons = [NSMutableArray new];
	[buttons addObject:ActionButtonSetName];
	if (!self.fit.managedObjectContext)
		[buttons addObject:ActionButtonSave];
	
	[buttons addObject:ActionButtonSetDamagePattern];

	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:nil
										 cancelButtonTitle:NSLocalizedString(ActionButtonCancel, nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   if (selectedButtonIndex == 0) {
													   self.fitNameTextField.text = self.fit.fitName;
													   self.navigationItem.titleView = self.fitNameTextField;
													   [self.fitNameTextField becomeFirstResponder];
												   }
												   else if (selectedButtonIndex == 1 && !self.fit.managedObjectContext) {
													   [self.fit save];
												   }
												   else {
													   DamagePatternsViewController *damagePatternsViewController = [[DamagePatternsViewController alloc] initWithNibName:@"DamagePatternsViewController" bundle:nil];
													   damagePatternsViewController.delegate = self;
													   damagePatternsViewController.currentDamagePattern = self.damagePattern;
													   
													   UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:damagePatternsViewController];
													   navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
													   
													   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
														   navController.modalPresentationStyle = UIModalPresentationFormSheet;
													   
													   [self presentViewController:navController animated:YES completion:nil];
												   }
												   
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onBack:(id) sender {
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
}

- (eufe::Engine*) fittingEngine {
	if (!_fittingEngine)
		_fittingEngine = new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
	return _fittingEngine;
}

- (void) update {
	[(POSFittingDataSource*) self.tableView.dataSource reload];
}

- (void) setFit:(POSFit*) value {
	_fit = value;
	//boost::shared_ptr<eufe::ControlTower> controlTower = fit.controlTower;
//	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", _fit.typeName, _fit.fitName ? _fit.fitName : _fit.typeName];
	self.fitNameTextField.text = _fit.fitName;
}

- (void) setDamagePattern:(DamagePattern *)value {
	_damagePattern = value;
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = _damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = _damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = _damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = _damagePattern.explosiveAmount;
	self.fit.controlTower->setDamagePattern(eufeDamagePattern);
}

- (EVEDBInvControlTowerResource*) posFuelRequirements {
	if (!_posFuelRequirements) {
		for (EVEDBInvControlTowerResource* resource in self.fit.type.resources) {
			if (resource.minSecurityLevel == 0.0 && resource.purposeID == 1) {
				_posFuelRequirements = resource;
				break;
			}
		}
	}
	return _posFuelRequirements;
}

- (NCItemsViewController*) itemsViewController {
	if (!_itemsViewController) {
		_itemsViewController = [[NCItemsViewController alloc] init];
	}
	return _itemsViewController;
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self.fitNameTextField resignFirstResponder];
	self.fit.fitName = self.fitNameTextField.text;
	
	self.navigationItem.titleView = nil;
	self.title = [NSString stringWithFormat:@"%@ - %@", self.fit.typeName, self.fit.fitName ? self.fit.fitName : self.fit.typeName];
	return YES;
}

#pragma mark DamagePatternsViewControllerDelegate

- (void) damagePatternsViewController:(DamagePatternsViewController*) controller didSelectDamagePattern:(DamagePattern*) aDamagePattern {
	self.damagePattern = aDamagePattern;
	[self update];
	[self dismiss];
}

#pragma mark - Private

- (void) save {
	self.fit.fitName = self.fitNameTextField.text;
	if (self.fit.managedObjectContext)
		[self.fit save];
}

@end
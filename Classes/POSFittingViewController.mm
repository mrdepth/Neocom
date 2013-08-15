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
#import "FittingItemsViewController.h"
#import "POSFit.h"
#import "ItemInfo.h"
#import "DamagePattern.h"
#import "RequiredSkillsViewController.h"
#import "EVEDBAPI.h"
#import "PriceManager.h"
#import "appearance.h"

#include "eufe.h"

#define ActionButtonBack NSLocalizedString(@"Back", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonAreaEffect NSLocalizedString(@"Select Area Effect", nil)
#define ActionButtonClearAreaEffect NSLocalizedString(@"Clear Area Effect", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface POSFittingViewController()
@property(nonatomic, strong) UIViewController<FittingSection> *currentSection;
@property(nonatomic, assign) NSInteger currentSectionIndex;
@property(nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, readwrite) eufe::Engine* fittingEngine;
@property (nonatomic, strong, readwrite) NCItemsViewController* itemsViewController;


- (void) keyboardWillShow: (NSNotification*) notification;
- (void) keyboardWillHide: (NSNotification*) notification;
- (void) save;

@end

@implementation POSFittingViewController
@synthesize popoverController;

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
	
	if (self.currentSectionIndex == 0)
		self.currentSection = self.structuresViewController;
	else if (self.currentSectionIndex == 1)
		self.currentSection = self.assemblyLinesViewController;
	else
		self.currentSection = self.posStatsViewController;
	
	[self.sectionsView addSubview:self.currentSection.view];
	self.currentSection.view.frame = self.sectionsView.bounds;
	[self.currentSection viewWillAppear:NO];
	
	self.sectionSegmentControl.selectedSegmentIndex = self.currentSectionIndex;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.statsSectionView addSubview:self.posStatsViewController.view];
		self.posStatsViewController.view.frame = self.statsSectionView.bounds;
		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.modalController];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
		
		self.structuresViewController.popoverController = self.popoverController;
	}
	
	self.priceManager = [[PriceManager alloc] init];
	
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Options", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onMenu:)]];
	[self update];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}
}	

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	}
	else {
		[self save];
	}
}

- (void) viewDidLayoutSubviews {
	self.currentSection.view.frame = self.sectionsView.bounds;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.sectionsView = nil;
	self.sectionSegmentControl = nil;
	self.modalController = nil;
	self.areaEffectsModalController = nil;
	self.areaEffectsViewController = nil;
	self.structuresViewController = nil;
	self.assemblyLinesViewController = nil;
	self.posStatsViewController = nil;
	self.shadeView = nil;
	self.fitNameView = nil;
	self.fitNameTextField = nil;
	self.statsSectionView = nil;
	self.popoverController = nil;
	self.areaEffectsPopoverController = nil;
	self.currentSection = nil;
	self.posFuelRequirements = nil;
	self.priceManager = nil;
}


- (void)dealloc {
	delete self.fittingEngine;
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) didChangeSection:(id) sender {
	UIViewController<FittingSection> *newSection = nil;
	if (self.sectionSegmentControl.selectedSegmentIndex == 0)
		newSection = self.structuresViewController;
	else if (self.sectionSegmentControl.selectedSegmentIndex == 1)
		newSection = self.assemblyLinesViewController;
	else
		newSection = self.posStatsViewController;
	if (newSection == self.currentSection)
		return;
	
	self.currentSectionIndex = self.sectionSegmentControl.selectedSegmentIndex;
	
	[self.currentSection.view removeFromSuperview];
	[self.sectionsView addSubview:newSection.view];
	newSection.view.frame = self.sectionsView.bounds;
	[newSection viewWillAppear:NO];
	self.currentSection = newSection;
}

- (IBAction) onMenu:(id) sender {
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
	}
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
											  delegate:self
									 cancelButtonTitle:nil
								destructiveButtonTitle:nil
									 otherButtonTitles:nil];
	
/*	if (fittingEngine->getArea() != NULL) {
		[actionSheet addButtonWithTitle:ActionButtonClearAreaEffect];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
	}*/
	
	[self.actionSheet addButtonWithTitle:ActionButtonSetName];
	if (!self.fit.managedObjectContext)
		[self.actionSheet addButtonWithTitle:ActionButtonSave];
	//[actionSheet addButtonWithTitle:ActionButtonAreaEffect];
	
	[self.actionSheet addButtonWithTitle:ActionButtonSetDamagePattern];
	[self.actionSheet addButtonWithTitle:ActionButtonCancel];
	
	self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
	
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id) sender {
	[self.fitNameTextField resignFirstResponder];
	self.fit.fitName = self.fitNameTextField.text;
	
//	boost::shared_ptr<eufe::ControlTower> controlTower = fit.controlTower;
//	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:controlTower error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", self.fit.typeName, self.fit.fitName ? self.fit.fitName : self.fit.typeName];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationBeginsFromCurrentState:YES];
		self.fitNameView.frame = CGRectMake(self.view.frame.size.width,
											self.fitNameView.frame.origin.y,
											self.fitNameView.frame.size.width,
											self.fitNameView.frame.size.height);
		[UIView commitAnimations];
	}
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

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)aActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [aActionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonBack]) {
		[self save];
		[self.navigationController popViewControllerAnimated:YES];
	}
	else if ([button isEqualToString:ActionButtonSetName]) {
		[self.fitNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:0.3];
			[UIView setAnimationBeginsFromCurrentState:YES];
			//			self.shadeView.alpha = 1;
			self.fitNameView.frame = CGRectMake(self.sectionsView.frame.size.width,
												self.fitNameView.frame.origin.y,
												self.fitNameView.frame.size.width,
												self.fitNameView.frame.size.height);
			[UIView commitAnimations];
		}
	}
	else if ([button isEqualToString:ActionButtonSave]) {
		[self.fit save];
	}
	else if ([button isEqualToString:ActionButtonAreaEffect]) {
		eufe::Item* area = self.fittingEngine->getArea();
		self.areaEffectsViewController.selectedArea = area != NULL ? [ItemInfo itemInfoWithItem:area error:nil] : nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self.areaEffectsPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:self.areaEffectsModalController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonClearAreaEffect]) {
		self.fittingEngine->clearArea();
		[self update];
	}
	else if ([button isEqualToString:ActionButtonSetDamagePattern]) {
		DamagePatternsViewController *damagePatternsViewController = [[DamagePatternsViewController alloc] initWithNibName:@"DamagePatternsViewController" bundle:nil];
		damagePatternsViewController.delegate = self;
		damagePatternsViewController.currentDamagePattern = self.damagePattern;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:damagePatternsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentModalViewController:navController animated:YES];
	}
	self.actionSheet = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self onDone:nil];
	return YES;
}

#pragma mark AreaEffectsViewControllerDelegate

- (void) areaEffectsViewController:(AreaEffectsViewController*) controller didSelectAreaEffect:(EVEDBInvType*) areaEffect {
	self.fittingEngine->setArea(areaEffect.typeID);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.areaEffectsPopoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
	[self update];
}

#pragma mark DamagePatternsViewControllerDelegate

- (void) damagePatternsViewController:(DamagePatternsViewController*) controller didSelectDamagePattern:(DamagePattern*) aDamagePattern {
	self.damagePattern = aDamagePattern;
	[self update];
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) aController didSelectType:(EVEDBInvType*) type {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[aController dismissModalViewControllerAnimated:YES];
	
	eufe::ControlTower* controlTower = self.fit.controlTower;
	
	if (type.group.categoryID == 8) {// Charge
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController dismissPopoverAnimated:YES];
		if (aController.modifiedItem) {
			eufe::Structure* structure = dynamic_cast<eufe::Structure*>(aController.modifiedItem.item);
			structure->setCharge(type.typeID);
		}
		else {
			eufe::StructuresList::const_iterator i, end = controlTower->getStructures().end();
			for (i = controlTower->getStructures().begin(); i != end; i++) {
				(*i)->setCharge(type.typeID);
			}
		}
	}
	else { //Module
		controlTower->addStructure(type.typeID);
	}
	[self update];
}

#pragma mark - Private

- (void) keyboardWillShow: (NSNotification*) notification {
	CGRect r = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	self.shadeView.alpha = 1;
	self.fitNameView.frame = CGRectMake(self.fitNameView.frame.origin.x,
										self.view.frame.size.height - r.size.height - self.fitNameView.frame.size.height,
										self.fitNameView.frame.size.width,
										self.fitNameView.frame.size.height);
	[UIView commitAnimations];
}

- (void) keyboardWillHide: (NSNotification*) notification {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:[[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	self.shadeView.alpha = 0;
	self.fitNameView.frame = CGRectMake(self.fitNameView.frame.origin.x, self.view.frame.size.height, self.fitNameView.frame.size.width, self.fitNameView.frame.size.height);
	[UIView commitAnimations];
}

- (void) save {
	if (self.fit.managedObjectContext)
		[self.fit save];
}

@end
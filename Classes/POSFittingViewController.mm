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

#include "eufe.h"

#define ActionButtonBack NSLocalizedString(@"Back", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonAreaEffect NSLocalizedString(@"Select Area Effect", nil)
#define ActionButtonClearAreaEffect NSLocalizedString(@"Clear Area Effect", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)

@interface POSFittingViewController(Private)

- (void) keyboardWillShow: (NSNotification*) notification;
- (void) keyboardWillHide: (NSNotification*) notification;
- (void) save;

@end

@implementation POSFittingViewController
@synthesize sectionsView;
@synthesize sectionSegmentControl;
@synthesize modalController;
@synthesize areaEffectsModalController;
@synthesize areaEffectsViewController;
@synthesize structuresViewController;
@synthesize assemblyLinesViewController;
@synthesize posStatsViewController;
@synthesize shadeView;
@synthesize fitNameView;
@synthesize fitNameTextField;
@synthesize statsSectionView;
@synthesize popoverController;
@synthesize areaEffectsPopoverController;
@synthesize fit;

@synthesize fittingEngine;
@synthesize damagePattern;

@synthesize posFuelRequirements;
@synthesize priceManager;

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
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)] autorelease];
	
	self.fitNameTextField.text = fit.fitName;
	self.damagePattern = [DamagePattern uniformDamagePattern];
	
	if (currentSectionIndex == 0)
		currentSection = structuresViewController;
	else if (currentSectionIndex == 1)
		currentSection = assemblyLinesViewController;
	else
		currentSection = posStatsViewController;
	
	[self.sectionsView addSubview:currentSection.view];
	currentSection.view.frame = self.sectionsView.bounds;
	[currentSection viewWillAppear:NO];
	
	sectionSegmentControl.selectedSegmentIndex = currentSectionIndex;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.statsSectionView addSubview:posStatsViewController.view];
		posStatsViewController.view.frame = self.statsSectionView.bounds;
		self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:modalController] autorelease];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;
		
//		self.areaEffectsPopoverController = [[[UIPopoverController alloc] initWithContentViewController:areaEffectsModalController] autorelease];
//		self.areaEffectsPopoverController.delegate = (AreaEffectsViewController*)  self.areaEffectsModalController.topViewController;
		
		structuresViewController.popoverController = self.popoverController;
	}
	
	priceManager = [[PriceManager alloc] init];
	
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Options", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onMenu:)] autorelease]];
	[self update];
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
	if (actionSheet) {
		[actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
		[actionSheet release];
		actionSheet = nil;
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
	currentSection.view.frame = self.sectionsView.bounds;
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
	currentSection = nil;
	self.posFuelRequirements = nil;
	self.priceManager = nil;
}


- (void)dealloc {
	
	[sectionsView release];
	[sectionSegmentControl release];
	[modalController release];
	[areaEffectsModalController release];
	[areaEffectsViewController release];
	[structuresViewController release];
	[assemblyLinesViewController release];
	[posStatsViewController release];
	[shadeView release];
	[fitNameView release];
	[fitNameTextField release];
	[statsSectionView release];
	[popoverController release];
	[areaEffectsPopoverController release];
	
	[fit release];
	
	[actionSheet release];
	[damagePattern release];
	
	[posFuelRequirements release];
	[priceManager release];

	delete fittingEngine;
    [super dealloc];
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) didChangeSection:(id) sender {
	UIViewController<FittingSection> *newSection = nil;
	if (sectionSegmentControl.selectedSegmentIndex == 0)
		newSection = structuresViewController;
	else if (sectionSegmentControl.selectedSegmentIndex == 1)
		newSection = assemblyLinesViewController;
	else
		newSection = posStatsViewController;
	if (newSection == currentSection)
		return;
	
	currentSectionIndex = sectionSegmentControl.selectedSegmentIndex;
	
	[currentSection.view removeFromSuperview];
	[self.sectionsView addSubview:newSection.view];
	newSection.view.frame = self.sectionsView.bounds;
	[newSection viewWillAppear:NO];
	currentSection = newSection;
}

- (IBAction) onMenu:(id) sender {
	if (actionSheet) {
		[actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
		[actionSheet release];
	}
	actionSheet = [[UIActionSheet alloc] initWithTitle:nil
											  delegate:self
									 cancelButtonTitle:nil
								destructiveButtonTitle:nil
									 otherButtonTitles:nil];
	
/*	if (fittingEngine->getArea() != NULL) {
		[actionSheet addButtonWithTitle:ActionButtonClearAreaEffect];
		actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
	}*/
	
	[actionSheet addButtonWithTitle:ActionButtonSetName];
	if (fit.fitID <= 0)
		[actionSheet addButtonWithTitle:ActionButtonSave];
	//[actionSheet addButtonWithTitle:ActionButtonAreaEffect];
	
	[actionSheet addButtonWithTitle:ActionButtonSetDamagePattern];
	[actionSheet addButtonWithTitle:ActionButtonCancel];
	
	actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
	
	[actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id) sender {
	[fitNameTextField resignFirstResponder];
	fit.fitName = fitNameTextField.text;
	
//	boost::shared_ptr<eufe::ControlTower> controlTower = fit.controlTower;
//	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:controlTower error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", fit.typeName, fit.fitName ? fit.fitName : fit.typeName];
	
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
	if (!fittingEngine)
		fittingEngine = new eufe::Engine([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]);
	return fittingEngine;
}

- (void) update {
	[currentSection update];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[posStatsViewController update];
}

- (void) setFit:(POSFit*) value {
	[value retain];
	[fit release];
	fit = value;
	//boost::shared_ptr<eufe::ControlTower> controlTower = fit.controlTower;
//	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", fit.typeName, fit.fitName ? fit.fitName : fit.typeName];
	self.fitNameTextField.text = fit.fitName;
}

- (void) setDamagePattern:(DamagePattern *)value {
	[value retain];
	[damagePattern release];
	damagePattern = value;
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = damagePattern.explosiveAmount;
	fit.controlTower->setDamagePattern(eufeDamagePattern);
}

- (EVEDBInvControlTowerResource*) posFuelRequirements {
	if (!posFuelRequirements) {
		for (EVEDBInvControlTowerResource* resource in fit.resources) {
			if (resource.minSecurityLevel == 0.0 && resource.purposeID == 1) {
				posFuelRequirements = [resource retain];
				break;
			}
		}
	}
	return posFuelRequirements;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)aActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [aActionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonBack]) {
		[self save];
		[self.navigationController popViewControllerAnimated:YES];
	}
	else if ([button isEqualToString:ActionButtonSetName]) {
		[fitNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2];
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
		[fit save];
	}
	else if ([button isEqualToString:ActionButtonAreaEffect]) {
		eufe::Item* area = fittingEngine->getArea();
		areaEffectsViewController.selectedArea = area != NULL ? [ItemInfo itemInfoWithItem:area error:nil] : nil;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[areaEffectsPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else
			[self presentModalViewController:areaEffectsModalController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonClearAreaEffect]) {
		fittingEngine->clearArea();
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
		[navController release];
		[damagePatternsViewController release];
	}
	[actionSheet release];
	actionSheet = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self onDone:nil];
	return YES;
}

#pragma mark AreaEffectsViewControllerDelegate

- (void) areaEffectsViewController:(AreaEffectsViewController*) controller didSelectAreaEffect:(EVEDBInvType*) areaEffect {
	fittingEngine->setArea(areaEffect.typeID);
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
	
	eufe::ControlTower* controlTower = fit.controlTower;
	
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

@end


@implementation POSFittingViewController(Private)

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
	if (fit.fitID > 0)
		[fit save];
}

@end
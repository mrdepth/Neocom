//
//  FittingViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingViewController.h"
#import "SelectCharacterBarButtonItem.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "FittingItemsViewController.h"
#import "ShipFit.h"
#import "ItemInfo.h"
#import "DamagePattern.h"
#import "RequiredSkillsViewController.h"
#import "PriceManager.h"
#import "UIActionSheet+Block.h"
#import "ItemViewController.h"

#include "eufe.h"

#define ActionButtonBack NSLocalizedString(@"Back", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonCharacter NSLocalizedString(@"Switch Character", nil)
#define ActionButtonViewInBrowser NSLocalizedString(@"View in Browser", nil)
#define ActionButtonAreaEffect NSLocalizedString(@"Select Area Effect", nil)
#define ActionButtonClearAreaEffect NSLocalizedString(@"Clear Area Effect", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonRequiredSkills NSLocalizedString(@"Required Skills", nil)
#define ActionButtonExport NSLocalizedString(@"Export", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDuplicate NSLocalizedString(@"Duplicate Fit", nil)
#define ActionButtonShowShipInfo NSLocalizedString(@"Ship Info", nil)

@interface FittingViewController()
@property (nonatomic, strong) UIViewController<FittingSection> *currentSection;
@property (nonatomic, assign) NSInteger currentSectionIndex;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, readwrite) eufe::Engine* fittingEngine;
@property (nonatomic, retain, readwrite) NSMutableArray* fits;


- (void) keyboardWillShow: (NSNotification*) notification;
- (void) keyboardWillHide: (NSNotification*) notification;
- (void) save;
- (void) performExport;

@end

@implementation FittingViewController
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
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)];
	
	self.fitNameTextField.text = self.fit.fitName;
	self.damagePattern = [DamagePattern uniformDamagePattern];

	if (self.currentSectionIndex == 0)
		self.currentSection = self.modulesViewController;
	else if (self.currentSectionIndex == 1)
		self.currentSection = self.dronesViewController;
	else if (self.currentSectionIndex == 2)
		self.currentSection = self.implantsViewController;
	else if (self.currentSectionIndex == 3)
		self.currentSection = self.fleetViewController;
	else if (self.currentSectionIndex == 4)
		self.currentSection = self.statsViewController;

	[self.sectionsView addSubview:self.currentSection.view];
	self.currentSection.view.frame = self.sectionsView.bounds;
	[self.currentSection viewWillAppear:NO];
	
	self.sectionSegmentControl.selectedSegmentIndex = self.currentSectionIndex;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.statsSectionView addSubview:self.statsViewController.view];
		self.statsViewController.view.frame = self.statsSectionView.bounds;
		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.modalController];
		self.popoverController.delegate = (FittingItemsViewController*)  self.modalController.topViewController;

		self.targetsPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.targetsModalController];
		self.targetsPopoverController.delegate = (FittingItemsViewController*)  self.targetsModalController.topViewController;
		
		self.areaEffectsPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.areaEffectsModalController];
		self.areaEffectsPopoverController.delegate = (AreaEffectsViewController*)  self.areaEffectsModalController.topViewController;
		
		self.modulesViewController.popoverController = self.popoverController;
		self.dronesViewController.popoverController = self.popoverController;
		self.implantsViewController.popoverController = self.popoverController;
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

- (void) viewDidLayoutSubviews {
	self.currentSection.view.frame = self.sectionsView.bounds;
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
	self.targetsModalController = nil;
	self.areaEffectsModalController = nil;
	self.areaEffectsViewController = nil;
	self.modulesViewController = nil;
	self.dronesViewController = nil;
	self.implantsViewController = nil;
	self.statsViewController = nil;
	self.fleetViewController = nil;
	self.shadeView = nil;
	self.fitNameView = nil;
	self.fitNameTextField = nil;
	self.statsSectionView = nil;
	self.popoverController = nil;
	self.targetsPopoverController = nil;
	self.areaEffectsPopoverController = nil;
	self.variationsPopoverController = nil;
	self.priceManager = nil;
	self.currentSection = nil;
}


- (void)dealloc {
	for (ShipFit* shipFit in self.fits)
		[shipFit unload];
	delete self.fittingEngine;
}

- (IBAction) didCloseModalViewController:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) didChangeSection:(id) sender {
	UIViewController<FittingSection> *newSection = nil;
	if (self.sectionSegmentControl.selectedSegmentIndex == 0)
		newSection = self.modulesViewController;
	else if (self.sectionSegmentControl.selectedSegmentIndex == 1)
		newSection = self.dronesViewController;
	else if (self.sectionSegmentControl.selectedSegmentIndex == 2)
		newSection = self.implantsViewController;
	else if (self.sectionSegmentControl.selectedSegmentIndex == 3)
		newSection = self.fleetViewController;
	else if (self.sectionSegmentControl.selectedSegmentIndex == 4)
		newSection = self.statsViewController;
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
//	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
//		[actionSheet addButtonWithTitle:ActionButtonBack];
	
	if (self.fittingEngine->getArea() != NULL) {
		[self.actionSheet addButtonWithTitle:ActionButtonClearAreaEffect];
		self.actionSheet.destructiveButtonIndex = self.actionSheet.numberOfButtons - 1;
	}

	[self.actionSheet addButtonWithTitle:ActionButtonShowShipInfo];
	[self.actionSheet addButtonWithTitle:ActionButtonSetName];
	if (!self.fit.managedObjectContext)
		[self.actionSheet addButtonWithTitle:ActionButtonSave];
	else
		[self.actionSheet addButtonWithTitle:ActionButtonDuplicate];
	[self.actionSheet addButtonWithTitle:ActionButtonCharacter];
	if (self.fit.url)
		[self.actionSheet addButtonWithTitle:ActionButtonViewInBrowser];
	[self.actionSheet addButtonWithTitle:ActionButtonAreaEffect];
	
	[self.actionSheet addButtonWithTitle:ActionButtonSetDamagePattern];
	[self.actionSheet addButtonWithTitle:ActionButtonRequiredSkills];
	[self.actionSheet addButtonWithTitle:ActionButtonExport];
	[self.actionSheet addButtonWithTitle:ActionButtonCancel];
	
	self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
	
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id) sender {
	[self.fitNameTextField resignFirstResponder];
	self.fit.fitName = self.fitNameTextField.text;
	
	eufe::Character* character = self.fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, self.fit.fitName ? self.fit.fitName : itemInfo.typeName];
	
	if (self.currentSection == self.fleetViewController)
		[self.fleetViewController update];

	
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
		//_fittingEngine = new eufe::Engine([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]);
		_fittingEngine = new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
	return _fittingEngine;
}

- (NSMutableArray*) fits {
	if (!_fits)
		_fits = [[NSMutableArray alloc] init];
	return _fits;
}

- (void) update {
	[self.currentSection update];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.statsViewController update];
}

- (void) addFleetMember {
	FitsViewController *fitsViewController = [[FitsViewController alloc] initWithNibName:@"FitsViewController" bundle:nil];
	fitsViewController.delegate = self;
	fitsViewController.engine = self.fittingEngine;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fitsViewController];
	navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self presentModalViewController:navController animated:YES];
}

- (void) selectCharacterForFit:(ShipFit*) aFit {
	CharactersViewController *charactersViewController = [[CharactersViewController alloc] initWithNibName:@"CharactersViewController" bundle:nil];
	charactersViewController.delegate = self;
	charactersViewController.modifiedFit = aFit;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:charactersViewController];
	navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self presentModalViewController:navController animated:YES];
}

- (void) setFit:(ShipFit*) value {
	_fit = value;
	eufe::Character* character = _fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, _fit.fitName ? _fit.fitName : itemInfo.typeName];
	self.fitNameTextField.text = _fit.fitName;
}

- (void) setDamagePattern:(DamagePattern *)value {
	_damagePattern = value;
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = _damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = _damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = _damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = _damagePattern.explosiveAmount;
	for (ShipFit* item in self.fits) {
		eufe::Character* character = item.character;
		character->getShip()->setDamagePattern(eufeDamagePattern);
	}
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)aActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *button = [aActionSheet buttonTitleAtIndex:buttonIndex];
	if ([button isEqualToString:ActionButtonBack]) {
		[self save];
		[self.navigationController popViewControllerAnimated:YES];
	}
	else if ([button isEqualToString:ActionButtonShowShipInfo]) {
		ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:self.fit.character->getShip() error:nil];
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController:itemViewController animated:YES];
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
	else if ([button isEqualToString:ActionButtonDuplicate]) {
		ShipFit* shipFit = [[ShipFit alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:self.fit.managedObjectContext] insertIntoManagedObjectContext:self.fit.managedObjectContext];
		shipFit.typeID = self.fit.typeID;
		shipFit.typeName = self.fit.typeName;
		shipFit.imageName = self.fit.imageName;
		shipFit.fitName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), self.fit.fitName ? self.fit.fitName : @""];
		shipFit.character = self.fit.character;
		[self.fits replaceObjectAtIndex:[self.fits indexOfObject:self.fit] withObject:shipFit];
		self.fit = shipFit;
		[self update];
	}
	else if ([button isEqualToString:ActionButtonCharacter]) {
		[self selectCharacterForFit:self.fit];
	}
	else if ([button isEqualToString:ActionButtonViewInBrowser]) {
		BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
		//controller.delegate = self;
		controller.startPageURL = [NSURL URLWithString:self.fit.url];
		[self presentModalViewController:controller animated:YES];
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
	else if ([button isEqualToString:ActionButtonRequiredSkills]) {
		RequiredSkillsViewController *requiredSkillsViewController = [[RequiredSkillsViewController alloc] initWithNibName:@"RequiredSkillsViewController" bundle:nil];
		requiredSkillsViewController.fit = self.fit;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:requiredSkillsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentModalViewController:navController animated:YES];
	}
	else if ([button isEqualToString:ActionButtonExport]) {
		[self performExport];
	}
	self.actionSheet = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self onDone:nil];
	return YES;
}

#pragma mark BrowserViewControllerDelegate

- (void) browserViewControllerDidFinish:(BrowserViewController*) controller {
	[self dismissModalViewControllerAnimated:YES];
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

#pragma mark CharactersViewControllerDelegate

- (void) charactersViewController:(CharactersViewController*) aController didSelectCharacter:(Character*) character {
	eufe::Character* eufeCharacter = aController.modifiedFit.character;
	eufeCharacter->setSkillLevels(*[character skillsMap]);
	eufeCharacter->setCharacterName([character.name cStringUsingEncoding:NSUTF8StringEncoding]);
	[self update];
	[self dismissModalViewControllerAnimated:YES];
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
	
	eufe::Ship* ship = self.fit.character->getShip();

	if (type.group.categoryID == 8) {// Charge
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController dismissPopoverAnimated:YES];
		if (aController.modifiedItem) {
			eufe::Module* module = dynamic_cast<eufe::Module*>(aController.modifiedItem.item);
			module->setCharge(type.typeID);
		}
		else {
			eufe::ModulesList::const_iterator i, end = ship->getModules().end();
			for (i = ship->getModules().begin(); i != end; i++) {
				(*i)->setCharge(type.typeID);
			}
		}
	}
	else if (type.group.categoryID == 18) {// Drone
		eufe::TypeID typeID = type.typeID;
		eufe::Ship* ship = self.fit.character->getShip();
		
		const eufe::DronesList& drones = ship->getDrones();
		eufe::Drone* sameDrone = NULL;
		eufe::DronesList::const_iterator i, end = drones.end();
		for (i = drones.begin(); i != end; i++) {
			if ((*i)->getTypeID() == typeID) {
				sameDrone = *i;
				break;
			}
		}
		eufe::Drone* drone = ship->addDrone(type.typeID);
		
		if (sameDrone)
			drone->setTarget(sameDrone->getTarget());
		else {
			int dronesLeft = ship->getMaxActiveDrones() - 1;
			for (;dronesLeft > 0; dronesLeft--)
				ship->addDrone(new eufe::Drone(*drone));
		}
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[popoverController dismissPopoverAnimated:YES];
	}
	else if (type.group.categoryID == 20) {// Implant
		if ([type.attributesDictionary valueForKey:@"331"]) {
			self.fit.character->addImplant(type.typeID);
		}
		else {
			self.fit.character->addBooster(type.typeID);
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[popoverController dismissPopoverAnimated:YES];
		}
	}
	else { //Module
		self.fit.character->getShip()->addModule(type.typeID);
	}
	[self update];
}

#pragma mark FitsViewControllerDelegate

- (void) fitsViewController:(FitsViewController*) aController didSelectFit:(ShipFit*) aFit {
	eufe::Character* character = aFit.character;
	self.fittingEngine->getGang()->addPilot(character);
	[self.fits addObject:aFit];
	
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = self.damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = self.damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = self.damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = self.damagePattern.explosiveAmount;
	character->getShip()->setDamagePattern(eufeDamagePattern);
	
	[self dismissModalViewControllerAnimated:YES];
	[self update];
}

#pragma mark TargetsViewControllerDelegate
- (void) targetsViewController:(TargetsViewController*) controller didSelectTarget:(eufe::Ship*) target {
	ItemInfo* itemInfo = controller.modifiedItem;
	if (itemInfo.group.categoryID == 18) { // Drone
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(itemInfo.item);
		eufe::TypeID typeID = drone->getTypeID();
		eufe::Ship* ship = self.fit.character->getShip();
		
		const eufe::DronesList& drones = ship->getDrones();
		eufe::DronesList::const_iterator i, end = drones.end();
		for (i = drones.begin(); i != end; i++) {
			if ((*i)->getTypeID() == typeID)
				(*i)->setTarget(target);
		}
	}
	else {
		eufe::Module* module = dynamic_cast<eufe::Module*>(itemInfo.item);
		module->setTarget(target);
	}
	[self update];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.targetsPopoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

#pragma mark FittingVariationsViewControllerDelegate

- (void) fittingVariationsViewController:(FittingVariationsViewController*) controller didSelectType:(EVEDBInvType*) type {
	eufe::Ship* ship = self.fit.character->getShip();

	if (controller.modifiedItem) {
		eufe::Module* module = dynamic_cast<eufe::Module*>(controller.modifiedItem.item);
		ship->replaceModule(module, type.typeID);
	}
	else {
		eufe::ModulesList modules = ship->getModules();
		NSInteger marketGroupID = type.marketGroupID;
		NSInteger typeID = type.typeID;
		for (auto module: modules) {
			ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:module error:nil];
			if (itemInfo.marketGroupID == marketGroupID)
				ship->replaceModule(module, typeID);
		}
	}
	[self update];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.variationsPopoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissModalViewControllerAnimated:YES];
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
	for (Fit* item in self.fits)
		if (item.managedObjectContext)
			[item save];
}

- (void) performExport {
	NSString* xml = [self.fit eveXML];
	NSString* dna = [self.fit dna];

	NSString* name;
	
	if (self.fit.fitName.length > 0)
		name = self.fit.fitName;
	else {
		eufe::Character* character = self.fit.character;
		eufe::Ship* ship = character->getShip();
		name = [[ItemInfo itemInfoWithItem:ship error:nil] typeName];
	}
	NSString* link = [NSString stringWithFormat:@"<a href=\"javascript:if (typeof CCPEVE != 'undefined') CCPEVE.showFitting('%@'); else window.open('fitting:%@');\">%@</a>", dna, dna, name];
	
	NSMutableArray* buttons = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Clipboard EVE XML", nil), NSLocalizedString(@"Clipboard DNA", nil), nil];
	if ([MFMailComposeViewController canSendMail])
		[buttons addObject:NSLocalizedString(@"Email", nil)];
	[[UIActionSheet actionSheetWithTitle:NSLocalizedString(@"Export", nil)
					   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
				  destructiveButtonTitle:nil
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *aActionSheet, NSInteger selectedButtonIndex) {
							 if (selectedButtonIndex == aActionSheet.cancelButtonIndex)
								 return;
							 
							 
							 if (selectedButtonIndex == 0) {
								 [[UIPasteboard generalPasteboard] setString:xml];
							 }
							 else if (selectedButtonIndex == 1) {
								 [[UIPasteboard generalPasteboard] setString:link];
							 }
							 else if (selectedButtonIndex == 2) {
								 MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
								 controller.mailComposeDelegate = self;
								 [controller setMessageBody:link isHTML:YES];
								 [controller setSubject:name];
								 [controller addAttachmentData:[xml dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/xml" fileName:[NSString stringWithFormat:@"%@.xml", name]];
								 [self presentModalViewController:controller animated:YES];
							 }
						 }
							 cancelBlock:nil] showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

@end
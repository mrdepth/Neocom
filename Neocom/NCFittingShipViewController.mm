//
//  NCFittingShipViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipViewController.h"
#import "NCFittingShipModulesDataSource.h"
#import "NCFittingShipDronesDataSource.h"
#import "NCFittingShipImplantsDataSource.h"
#import "NCFittingShipFleetDataSource.h"
#import "NCFittingShipStatsDataSource.h"
#import "EVEDBAPI.h"
#import "NCStorage.h"
#import "NCFitCharacter.h"
#import "NCAccount.h"
#import "NCFittingCharacterPickerViewController.h"
#import "NCFittingFitPickerViewController.h"
#import "NCFittingTargetsViewController.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingDamagePatternsViewController.h"
#import "NCFittingAreaEffectPickerViewController.h"
#import "NCFittingTypeVariationsViewController.h"
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"
#import "NCFittingRequiredSkillsViewController.h"
#import "NCFittingImplantSetsViewController.h"
#import "NCFittingShipAffectingSkillsViewController.h"
#import "NCStoryboardPopoverSegue.h"
#import "UIColor+Neocom.h"

#include <set>

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
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)

@interface NCFittingShipViewController ()<MFMailComposeViewControllerDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray* fits;
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Engine> engine;

@property (nonatomic, strong) NCFittingShipModulesDataSource* modulesDataSource;
@property (nonatomic, strong) NCFittingShipDronesDataSource* dronesDataSource;
@property (nonatomic, strong) NCFittingShipImplantsDataSource* implantsDataSource;
@property (nonatomic, strong) NCFittingShipFleetDataSource* fleetDataSource;
@property (nonatomic, strong) NCFittingShipStatsDataSource* statsDataSource;
@property (nonatomic, strong) NSMutableDictionary* typesCache;
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong) UIActionSheet* actionSheet;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

- (void) performExport;
@end

@implementation NCFittingShipViewController

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
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	
	for (id controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingShipWorkspaceViewController class]])
			self.workspaceViewController = controller;
		else if ([controller isKindOfClass:[NCFittingShipStatsViewController class]])
			self.statsViewController = controller;
	}
	
	if (!self.engine)
		self.engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	
	if (!self.fits)
		self.fits = [[NSMutableArray alloc] initWithObjects:self.fit, nil];
	NCShipFit* fit = self.fit;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (!fit.pilot) {
													 fit.pilot = self.engine->getGang()->addPilot();
													 NCAccount* account = [NCAccount currentAccount];
													 NCFitCharacter* character;
													 
													 if (account.characterSheet)
														 character = [[NCStorage sharedStorage] characterWithAccount:account];
													 else
														 character = [[NCStorage sharedStorage] characterWithSkillsLevel:5];
													 
													 fit.character = character;
													 [fit load];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.modulesDataSource = [NCFittingShipModulesDataSource new];
								 self.modulesDataSource.controller = self;
								 self.modulesDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.dronesDataSource = [NCFittingShipDronesDataSource new];
								 self.dronesDataSource.controller = self;
								 self.dronesDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.implantsDataSource = [NCFittingShipImplantsDataSource new];
								 self.implantsDataSource.controller = self;
								 self.implantsDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.fleetDataSource = [NCFittingShipFleetDataSource new];
								 self.fleetDataSource.controller = self;
								 self.fleetDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.statsDataSource = [NCFittingShipStatsDataSource new];
								 self.statsDataSource.controller = self;
								 if (self.statsViewController) {
									 self.statsDataSource.tableView = self.statsViewController.tableView;
									 self.statsViewController.tableView.dataSource = self.statsDataSource;
									 self.statsViewController.tableView.delegate = self.statsDataSource;
								 }
								 else {
									 self.statsDataSource.tableView = self.workspaceViewController.tableView;
								 }
								 
								 NCFittingShipDataSource* dataSources[] = {self.modulesDataSource, self.dronesDataSource, self.implantsDataSource, self.fleetDataSource, self.statsDataSource};
								 NCFittingShipDataSource* dataSource = dataSources[self.sectionSegmentedControl.selectedSegmentIndex];
								 
								 self.workspaceViewController.tableView.dataSource = dataSource;
								 self.workspaceViewController.tableView.delegate = dataSource;
								 self.workspaceViewController.tableView.tableHeaderView = dataSource.tableHeaderView;
								 [self reload];
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	if (parent == nil) {
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 @synchronized(self) {
													 for (NCShipFit* fit in self.fits) {
														 if (fit.loadout)
															 [fit save];
													 }

													 [[[NCStorage sharedStorage] managedObjectContext] performBlockAndWait:^{
														 [[NCStorage sharedStorage] saveContext];
													 }];
												 }
											 }
								 completionHandler:^(NCTask *task) {
									 
								 }];
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isKindOfClass:[NCStoryboardPopoverSegue class]]) {
		NCStoryboardPopoverSegue* popoverSegue = (NCStoryboardPopoverSegue*) segue;
		id anchor = sender;
		if ([sender isKindOfClass:[NSDictionary class]])
			anchor = sender[@"sender"];
		
		if ([anchor isKindOfClass:[UIBarButtonItem class]])
			popoverSegue.anchorBarButtonItem = anchor;
		else if ([anchor isKindOfClass:[UIView class]])
			popoverSegue.anchorView = anchor;
		else
			popoverSegue.anchorBarButtonItem = self.navigationItem.rightBarButtonItem;
	}
	
	if ([segue.identifier isEqualToString:@"NCFittingCharacterPickerViewController"]) {
		NCFittingCharacterPickerViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.fit = sender[@"object"];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingTargetsViewController"]) {
		NCFittingTargetsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		NSArray* items = sender[@"object"];
		eufe::Item* item = reinterpret_cast<eufe::Item*>([items[0] pointerValue]);
		controller.items = items;
		
		eufe::Module* module = dynamic_cast<eufe::Module*>(item);
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(item);
		
		eufe::Ship* target = nullptr;
		if (module)
			target = module->getTarget();
		else if (drone)
			target = drone->getTarget();
		if (target) {
			for (NCShipFit* fit in self.fits) {
				if (fit.pilot->getShip() == target) {
					controller.selectedTarget = fit;
					break;
				}
			}
		}
		
		NSMutableArray* targets = [[NSMutableArray alloc] initWithArray:self.fits];
		[targets removeObject:self.fit];
		controller.targets = targets;
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender[@"object"] pointerValue]);
		EVEDBInvType* type = [self typeWithItem:item];
		
		[type.attributesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* attributeID, EVEDBDgmTypeAttribute* attribute, BOOL *stop) {
			attribute.value = item->getAttribute(attribute.attributeID)->getValue();
		}];
		controller.type = (id) type;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingDamagePatternsViewController"]) {
		NCFittingDamagePatternsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.selectedDamagePattern = self.damagePattern;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAreaEffectPickerViewController"]) {
		NCFittingAreaEffectPickerViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		eufe::Area* area = self.engine->getArea();
		if (area)
			controller.selectedAreaEffect = [EVEDBInvType invTypeWithTypeID:area->getTypeID() error:nil];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingTypeVariationsViewController"]) {
		NCFittingTypeVariationsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		NSArray* modules = sender[@"object"];
		controller.object = modules;
		eufe::Item* item = reinterpret_cast<eufe::Item*>([modules[0] pointerValue]);
		controller.type = [self typeWithItem:item];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingRequiredSkillsViewController"]) {
		NCFittingRequiredSkillsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.trainingQueue = sender[@"object"];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingShipAffectingSkillsViewController"]) {
		NCFittingShipAffectingSkillsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		NSMutableArray* typeIDs = [NSMutableArray new];
		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender[@"object"] pointerValue]);
		for (auto item: item->getAffectors()) {
			eufe::Skill* skill = dynamic_cast<eufe::Skill*>(item);
			if (skill) {
				[typeIDs addObject:@((NSInteger) item->getTypeID())];
			}
		}
		
		controller.affectingSkillsTypeIDs = typeIDs;
		controller.character = self.fit.character;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingImplantSetsViewControllerSave"]) {
		NCFittingImplantSetsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		NSMutableArray* implants = [NSMutableArray new];
		for (auto implant: self.fit.pilot->getImplants())
			[implants addObject:@(implant->getTypeID())];

		NSMutableArray* boosters = [NSMutableArray new];
		for (auto booster: self.fit.pilot->getBoosters())
			[boosters addObject:@(booster->getTypeID())];

		NCImplantSetData* data = [NCImplantSetData new];
		data.implantIDs = implants;
		data.boosterIDs = boosters;

		controller.implantSetData = data;
		controller.saveMode = YES;
	}
}

- (EVEDBInvType*) typeWithItem:(eufe::Item*) item {
	if (!item)
		return nil;
	@synchronized(self) {
		if (!self.typesCache)
			self.typesCache = [NSMutableDictionary new];
		int typeID = item->getTypeID();
		
		EVEDBInvType* type = self.typesCache[@(typeID)];
		if (!type) {
			type = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
			if (type)
				self.typesCache[@(typeID)] = type;
		}
		return type;
	}
}

- (void) reload {
	[(id) self.workspaceViewController.tableView.dataSource reload];
	[(id) self.statsViewController.tableView.dataSource reload];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (IBAction)onChangeSection:(id)sender {
	NCFittingShipDataSource* dataSources[] = {self.modulesDataSource, self.dronesDataSource, self.implantsDataSource, self.fleetDataSource, self.statsDataSource};
	NCFittingShipDataSource* dataSource = dataSources[self.sectionSegmentedControl.selectedSegmentIndex];
	
	self.workspaceViewController.tableView.dataSource = dataSource;
	self.workspaceViewController.tableView.delegate = dataSource;
	self.workspaceViewController.tableView.tableHeaderView = dataSource.tableHeaderView;
	[dataSource reload];
}

- (IBAction)onAction:(id)sender {
	if (!self.fit.character)
		return;
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^clearAreaEffect)() = ^() {
		self.engine->clearArea();
		[self reload];
	};
	
	void (^shipInfo)() = ^() {
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
								  sender:@{@"sender": sender, @"object": [NSValue valueWithPointer:self.fit.pilot->getShip()]}];
	};
	
	void (^rename)() = ^() {
		UIAlertView* alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Rename", nil)
														 message:nil
											   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											   otherButtonTitles:@[NSLocalizedString(@"Rename", nil)]
												 completionBlock:^(UIAlertView *alertView, NSInteger selectedButtonIndex) {
													 if (selectedButtonIndex != alertView.cancelButtonIndex) {
														 UITextField* textField = [alertView textFieldAtIndex:0];
														 self.fit.loadoutName = textField.text;
														 self.title = self.fit.loadoutName;
													 }
												 } cancelBlock:nil];
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField* textField = [alertView textFieldAtIndex:0];
		textField.text = self.fit.loadoutName;
		[alertView show];
	};
	
	void (^save)() = ^() {
		[self.fit save];
		[[[NCStorage sharedStorage] managedObjectContext] performBlockAndWait:^{
			[[NCStorage sharedStorage] saveContext];
		}];
	};
	
	void (^duplicate)() = ^() {
		[self.fit save];
		NCStorage* storage = [NCStorage sharedStorage];
		self.fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
		self.fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:storage.managedObjectContext] insertIntoManagedObjectContext:storage.managedObjectContext];
		self.fit.loadoutName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), self.fit.loadoutName ? self.fit.loadoutName : @""];
		self.title = self.fit.loadoutName;
	};
	
	void (^setCharacter)() = ^() {
		[self performSegueWithIdentifier:@"NCFittingCharacterPickerViewController"
								  sender:@{@"sender": sender, @"object": self.fit}];
	};
	
	void (^viewInBrowser)() = ^() {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.fit.loadout.url]];
	};
	
	void (^setAreaEffect)() = ^() {
		[self performSegueWithIdentifier:@"NCFittingAreaEffectPickerViewController" sender:sender];
	};
	
	void (^setDamagePattern)() = ^() {
		[self performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:sender];
	};
	
	void (^requiredSkills)() = ^() {
		NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithAccount:[NCAccount currentAccount]];
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 @synchronized(self) {
													 std::set<eufe::TypeID> typeIDs;
													 eufe::Character* character = self.fit.pilot;
													 eufe::Ship* ship = character->getShip();
													 typeIDs.insert(ship->getTypeID());
													 
													 for (auto module: ship->getModules()) {
														 typeIDs.insert(module->getTypeID());
														 eufe::Charge* charge = module->getCharge();
														 if (charge)
															 typeIDs.insert(charge->getTypeID());
													 }
													 
													 for (auto drone: ship->getDrones())
														 typeIDs.insert(drone->getTypeID());

													 for (auto implant: character->getImplants())
														 typeIDs.insert(implant->getTypeID());

													 for (auto booster: character->getBoosters())
														 typeIDs.insert(booster->getTypeID());

													 for (auto typeID: typeIDs)
														 [trainingQueue addRequiredSkillsForType:[EVEDBInvType invTypeWithTypeID:typeID error:nil]];
												 }
											 }
								 completionHandler:^(NCTask *task) {
									 if (![task isCancelled]) {
										 [self performSegueWithIdentifier:@"NCFittingRequiredSkillsViewController"
																   sender:@{@"sender": sender, @"object": trainingQueue}];
									 }
								 }];
	};
	
	void (^exportFit)() = ^() {
		[self performExport];
	};
	
	void (^affectingSkills)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
								  sender:@{@"sender": sender, @"object": [NSValue valueWithPointer:self.fit.pilot->getShip()]}];
	};

	
	if (self.engine->getArea() != NULL)
		[actions addObject:clearAreaEffect];
	
	[actions addObject:shipInfo];
	[buttons addObject:ActionButtonShowShipInfo];
	
	[actions addObject:rename];
	[buttons addObject:ActionButtonSetName];
	
	if (!self.fit.loadout.managedObjectContext) {
		[actions addObject:save];
		[buttons addObject:ActionButtonSave];
	}
	else {
		[actions addObject:duplicate];
		[buttons addObject:ActionButtonDuplicate];
	}
	
	[actions addObject:setCharacter];
	[buttons addObject:ActionButtonCharacter];
	
	if (self.fit.loadout.url) {
		[actions addObject:viewInBrowser];
		[buttons addObject:ActionButtonViewInBrowser];
	}
	
	[actions addObject:setAreaEffect];
	[buttons addObject:ActionButtonAreaEffect];
	
	[actions addObject:setDamagePattern];
	[buttons addObject:ActionButtonSetDamagePattern];
	
	[actions addObject:requiredSkills];
	[buttons addObject:ActionButtonRequiredSkills];
	
	[actions addObject:exportFit];
	[buttons addObject:ActionButtonExport];
	
	[buttons addObject:ActionButtonAffectingSkills];
	[actions addObject:affectingSkills];

	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:self.engine->getArea() != NULL ? ActionButtonClearAreaEffect : nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   self.actionSheet = nil;
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   void (^action)() = actions[selectedButtonIndex];
												   action();
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void) setFit:(NCShipFit *)fit {
	_fit = fit;
	self.title = fit.loadoutName;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissAnimated];
}

#pragma mark - Private

- (IBAction) unwindFromCharacterPicker:(UIStoryboardSegue*) segue {
	NCFittingCharacterPickerViewController* sourceViewController = segue.sourceViewController;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (sourceViewController.selectedCharacter)
													 sourceViewController.fit.character = sourceViewController.selectedCharacter;
												 else if ([sourceViewController.fit.character isDeleted]) {
													 sourceViewController.fit.character = [[NCStorage sharedStorage] characterWithSkillsLevel:5];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 [self reload];
							 }];
}

- (IBAction) unwindFromFitPicker:(UIStoryboardSegue*) segue {
	NCFittingFitPickerViewController* sourceViewController = segue.sourceViewController;
	NCShipFit* fit = sourceViewController.selectedFit;
	if (!fit)
		return;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (!fit.pilot) {
													 fit.pilot = self.engine->getGang()->addPilot();
													 NCAccount* account = [NCAccount currentAccount];
													 NCFitCharacter* character;
													 
													 if (account.characterSheet)
														 character = [[NCStorage sharedStorage] characterWithAccount:account];
													 else
														 character = [[NCStorage sharedStorage] characterWithSkillsLevel:5];
													 
													 fit.character = character;
													 [fit load];
												 }

												 
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 [self.fits addObject:fit];
								 [self reload];
							 }];
}

- (IBAction) unwindFromTargets:(UIStoryboardSegue*) segue {
	NCFittingTargetsViewController* sourceViewController = segue.sourceViewController;
	eufe::Ship* target = sourceViewController.selectedTarget ? sourceViewController.selectedTarget.pilot->getShip() : nullptr;

	for (NSValue* value in sourceViewController.items) {
		eufe::Item* item = reinterpret_cast<eufe::Item*>([value pointerValue]);
		eufe::Module* module = dynamic_cast<eufe::Module*>(item);
		eufe::Drone* drone = dynamic_cast<eufe::Drone*>(item);
		
		if (module)
			module->setTarget(target);
		else if (drone)
			drone->setTarget(target);
	}
	[self reload];
}

- (IBAction) unwindFromDamagePatterns:(UIStoryboardSegue*) segue {
	NCFittingDamagePatternsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedDamagePattern) {
		eufe::DamagePattern damagePattern;
		damagePattern.emAmount = sourceViewController.selectedDamagePattern.em;
		damagePattern.thermalAmount = sourceViewController.selectedDamagePattern.thermal;
		damagePattern.kineticAmount = sourceViewController.selectedDamagePattern.kinetic;
		damagePattern.explosiveAmount = sourceViewController.selectedDamagePattern.explosive;
		
		self.damagePattern = sourceViewController.selectedDamagePattern;
		for (NCShipFit* fit in self.fits) {
			eufe::Ship* ship = fit.pilot->getShip();
			ship->setDamagePattern(damagePattern);
		}
		[self reload];
	}
}

- (IBAction) unwindFromAreaEffectPicker:(UIStoryboardSegue*) segue {
	NCFittingAreaEffectPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedAreaEffect) {
		self.engine->setArea(sourceViewController.selectedAreaEffect.typeID);
		[self reload];
	}
}

- (IBAction) unwindFromTypeVariations:(UIStoryboardSegue*) segue {
	NCFittingTypeVariationsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedType) {
		eufe::Ship* ship = self.fit.pilot->getShip();
		eufe::TypeID typeID = sourceViewController.selectedType.typeID;

		for (NSValue* value in sourceViewController.object) {
			eufe::Module* module = reinterpret_cast<eufe::Module*>([value pointerValue]);
			ship->replaceModule(module, typeID);
		}
		[self reload];
	}
}

- (IBAction) unwindFromImplantSets:(UIStoryboardSegue*) segue {
	NCFittingImplantSetsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedImplantSet) {
		eufe::Character* character = self.fit.pilot;
		eufe::ImplantsList implants = character->getImplants();
		for (auto implant: implants)
			character->removeImplant(implant);
		for (NSNumber* typeID in [(NCImplantSetData*) sourceViewController.selectedImplantSet.data implantIDs]) {
			character->addImplant([typeID intValue]);
		}
		
		eufe::BoostersList boosters = character->getBoosters();
		for (auto booster: boosters)
			character->removeBooster(booster);
		for (NSNumber* typeID in [(NCImplantSetData*) sourceViewController.selectedImplantSet.data boosterIDs]) {
			character->addBooster([typeID intValue]);
		}

		[self reload];
	}
}

- (IBAction) unwindFromAffectingSkills:(UIStoryboardSegue*) segue {
	NCFittingShipAffectingSkillsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.modified) {
		[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
											 title:NCTaskManagerDefaultTitle
											 block:^(NCTask *task) {
												 @synchronized(self) {
													 self.fit.character = sourceViewController.character;
												 }
											 }
								 completionHandler:^(NCTask *task) {
									 [self reload];
								 }];
	}
}

- (void) performExport {
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	NSMutableArray* buttons = [NSMutableArray arrayWithObjects:
							   NSLocalizedString(@"Copy Link", nil),
							   NSLocalizedString(@"Copy DNA", nil),
							   NSLocalizedString(@"Copy EFT", nil),
							   NSLocalizedString(@"Copy EVE XML", nil),
							   NSLocalizedString(@"Open EVE XML in ...", nil),
							   NSLocalizedString(@"Open EFT in ...", nil),
							   nil];
	if ([MFMailComposeViewController canSendMail])
		[buttons addObject:NSLocalizedString(@"Email", nil)];
		
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   self.actionSheet = nil;
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   
												   if (selectedButtonIndex == 0) {
													   __block NSError* error = nil;
													   NSString* dna = self.fit.dnaRepresentation;
													   __block NSString* shortenLink = nil;
													   [[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
																							title:NCTaskManagerDefaultTitle
																							block:^(NCTask *task) {
																								NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://is.gd/create.php?format=json&url=fitting:%@", dna]]];
																								NSData* data = [NSURLConnection sendSynchronousRequest:request
																																	 returningResponse:nil
																																				 error:&error];
																								if (data) {
																									NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
																									if ([result isKindOfClass:[NSDictionary class]])
																										shortenLink = result[@"shorturl"];
																									else
																										error = [NSError errorWithDomain:@"is.gd"
																																	code:0
																																userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown Error", nil)}];
																								}
																							}
																				completionHandler:^(NCTask *task) {
																					[[UIPasteboard generalPasteboard] setString:shortenLink];
																				}];
													   [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"fitting:%@", self.fit.dnaRepresentation]];
												   }
												   else if (selectedButtonIndex == 1)
													   [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"fitting:%@", self.fit.dnaRepresentation]];
												   else if (selectedButtonIndex == 2)
													   [[UIPasteboard generalPasteboard] setString:self.fit.eftRepresentation];
												   else if (selectedButtonIndex == 3)
													   [[UIPasteboard generalPasteboard] setString:self.fit.eveXMLRepresentation];
												   else if (selectedButtonIndex == 4) {
													   NSData* data = [[self.fit eveXMLRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
													   NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.xml", self.fit.type.typeName, self.fit.loadoutName]];
													   [data writeToFile:path atomically:YES];
													   self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
													   [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
												   }
												   else if (selectedButtonIndex == 5) {
													   NSData* data = [[self.fit eftRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
													   NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.cfg", self.fit.type.typeName, self.fit.loadoutName]];
													   [data writeToFile:path atomically:YES];
													   self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
													   [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
												   }
												   else if (selectedButtonIndex == 6) {
													   NSString* tag = self.fit.hyperlinkTag;
													   NSMutableString* message = [NSMutableString stringWithFormat:@"%@\n<pre>\n%@\n</pre>Generated by <a href=\"https://itunes.apple.com/us/app/neocom/id418895101?mt=8\">Neocom</a>", tag, self.fit.eftRepresentation];
													   MFMailComposeViewController* controller = [MFMailComposeViewController new];
													   [controller setSubject:[NSString stringWithFormat:@"%@ - %@", self.fit.type.typeName, self.fit.loadoutName]];
													   [controller setMessageBody:message isHTML:YES];
													   [controller addAttachmentData:[self.fit.eveXMLRepresentation dataUsingEncoding:NSUTF8StringEncoding]
																			mimeType:@"application/xml"
																			fileName:[NSString stringWithFormat:@"%@.xml", self.fit.loadoutName]];
													   controller.mailComposeDelegate = self;
													   [self presentViewController:controller animated:YES completion:nil];
												   }
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

@end

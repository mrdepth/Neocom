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
#import "NCFittingAmountViewController.h"
#import "NCFittingDamagePatternsViewController.h"
#import "NCFittingAreaEffectPickerViewController.h"
#import "NCFittingTypeVariationsViewController.h"
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"
#import "NCFittingRequiredSkillsViewController.h"
#import "NCFittingImplantsImportViewController.h"
#import "NCFittingShipAffectingSkillsViewController.h"

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

@interface NCFittingShipViewController ()
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
	
	self.workspaceViewController = self.childViewControllers[0];
	
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
														 character = [NCFitCharacter characterWithAccount:account];
													 else
														 character = [NCFitCharacter characterWithSkillsLevel:5];
													 
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
								 self.statsDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.workspaceViewController.tableView.dataSource = self.modulesDataSource;
								 self.workspaceViewController.tableView.delegate = self.modulesDataSource;
								 self.workspaceViewController.tableView.tableHeaderView = self.modulesDataSource.tableHeaderView;
								 
								 [self.modulesDataSource reload];
							 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	if (self.view.window == nil) {
		self.modulesDataSource = nil;
		self.dronesDataSource = nil;
		self.implantsDataSource = nil;
		self.fleetDataSource = nil;
		self.statsDataSource = nil;
		self.typePickerViewController = nil;
	}
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
	if ([segue.identifier isEqualToString:@"NCFittingCharacterPickerViewController"]) {
		NCFittingCharacterPickerViewController* controller = [[segue destinationViewController] viewControllers][0];
		controller.fit = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingTargetsViewController"]) {
		NCFittingTargetsViewController* controller = [[segue destinationViewController] viewControllers][0];
		NSArray* items = sender;
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
		NCDatabaseTypeInfoViewController* destinationViewController = [segue destinationViewController];
		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender pointerValue]);
		EVEDBInvType* type = [self typeWithItem:item];
		
		[type.attributesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* attributeID, EVEDBDgmTypeAttribute* attribute, BOOL *stop) {
			attribute.value = item->getAttribute(attribute.attributeID)->getValue();
		}];
		destinationViewController.type = type;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAmountViewController"]) {
		NSArray* drones = sender;
		eufe::Ship* ship = self.fit.pilot->getShip();
		NCFittingAmountViewController* controller = [[segue destinationViewController] viewControllers][0];
		eufe::Drone* drone = reinterpret_cast<eufe::Drone*>([drones[0] pointerValue]);
		float volume = drone->getAttribute(eufe::VOLUME_ATTRIBUTE_ID)->getValue();
		int droneBay = ship->getTotalDroneBay() / volume;
		int maxActive = ship->getMaxActiveDrones();
		
		controller.range = NSMakeRange(1, std::min(std::max(droneBay, maxActive), 50));
		controller.amount = drones.count;
		controller.object = drones;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingDamagePatternsViewController"]) {
		NCFittingDamagePatternsViewController* controller = [[segue destinationViewController] viewControllers][0];
		controller.selectedDamagePattern = self.damagePattern;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAreaEffectPickerViewController"]) {
		NCFittingAreaEffectPickerViewController* controller = [[segue destinationViewController] viewControllers][0];
		eufe::Area* area = self.engine->getArea();
		if (area)
			controller.selectedAreaEffect = [EVEDBInvType invTypeWithTypeID:area->getTypeID() error:nil];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingTypeVariationsViewController"]) {
		NCFittingTypeVariationsViewController* controller = [[segue destinationViewController] viewControllers][0];
		NSArray* modules = sender;
		controller.object = modules;
		eufe::Item* item = reinterpret_cast<eufe::Item*>([modules[0] pointerValue]);
		controller.type = [self typeWithItem:item];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingRequiredSkillsViewController"]) {
		NCFittingRequiredSkillsViewController* destinationViewController = [segue destinationViewController];
		destinationViewController.trainingQueue = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingShipAffectingSkillsViewController"]) {
		NCFittingShipAffectingSkillsViewController* controller = [[segue destinationViewController] viewControllers][0];
		
		NSMutableArray* typeIDs = [NSMutableArray new];
		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender pointerValue]);
		for (auto item: item->getAffectors()) {
			eufe::Skill* skill = dynamic_cast<eufe::Skill*>(item);
			if (skill) {
				[typeIDs addObject:@((NSInteger) item->getTypeID())];
			}
		}
		
		controller.affectingSkillsTypeIDs = typeIDs;
		controller.character = self.fit.character;
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
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (IBAction)onChangeSection:(id)sender {
	if (self.sectionSegmentedControl.selectedSegmentIndex == 0) {
		self.workspaceViewController.tableView.dataSource = self.modulesDataSource;
		self.workspaceViewController.tableView.delegate = self.modulesDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.modulesDataSource.tableHeaderView;
		[self.modulesDataSource reload];
	}
	else if (self.sectionSegmentedControl.selectedSegmentIndex == 1) {
		self.workspaceViewController.tableView.dataSource = self.dronesDataSource;
		self.workspaceViewController.tableView.delegate = self.dronesDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.dronesDataSource.tableHeaderView;
		[self.dronesDataSource reload];
	}
	else if (self.sectionSegmentedControl.selectedSegmentIndex == 2) {
		self.workspaceViewController.tableView.dataSource = self.implantsDataSource;
		self.workspaceViewController.tableView.delegate = self.implantsDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.implantsDataSource.tableHeaderView;
		[self.implantsDataSource reload];
	}
	else if (self.sectionSegmentedControl.selectedSegmentIndex == 3) {
		self.workspaceViewController.tableView.dataSource = self.fleetDataSource;
		self.workspaceViewController.tableView.delegate = self.fleetDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.fleetDataSource.tableHeaderView;
		[self.fleetDataSource reload];
	}
	else {
		self.workspaceViewController.tableView.dataSource = self.statsDataSource;
		self.workspaceViewController.tableView.delegate = self.statsDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.statsDataSource.tableHeaderView;
		[self.statsDataSource reload];
	}
}

- (IBAction)onAction:(id)sender {
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^clearAreaEffect)() = ^() {
		self.engine->clearArea();
		[self reload];
	};
	
	void (^shipInfo)() = ^() {
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[NSValue valueWithPointer:self.fit.pilot->getShip()]];
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
		[self performSegueWithIdentifier:@"NCFittingCharacterPickerViewController" sender:self.fit];
	};
	
	void (^viewInBrowser)() = ^() {
/*		BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
		//controller.delegate = self;
		controller.startPageURL = [NSURL URLWithString:self.fit.url];
		[self presentViewController:controller animated:YES completion:nil];*/
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
										 [self performSegueWithIdentifier:@"NCFittingRequiredSkillsViewController" sender:trainingQueue];
									 }
								 }];
	};
	
	void (^exportFit)() = ^() {
		//[self performExport];
	};
	
	void (^affectingSkills)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController" sender:[NSValue valueWithPointer:self.fit.pilot->getShip()]];
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
	
	
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:self.engine->getArea() != NULL ? ActionButtonClearAreaEffect : nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   void (^action)() = actions[selectedButtonIndex];
												   action();
											   }
											   self.actionSheet = nil;
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void) setFit:(NCShipFit *)fit {
	_fit = fit;
	self.title = fit.loadoutName;
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
													 sourceViewController.fit.character = [NCFitCharacter characterWithSkillsLevel:5];
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
														 character = [NCFitCharacter characterWithAccount:account];
													 else
														 character = [NCFitCharacter characterWithSkillsLevel:5];
													 
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

- (IBAction) unwindFromAmount:(UIStoryboardSegue*) segue {
	NCFittingAmountViewController* sourceViewController = segue.sourceViewController;
	NSArray* drones = sourceViewController.object;
	eufe::Ship* ship = self.fit.pilot->getShip();
	if (drones.count > sourceViewController.amount) {
		NSInteger n = drones.count - sourceViewController.amount;
		for (NSValue* value in drones) {
			if (n <= 0)
				break;
			eufe::Drone* drone = reinterpret_cast<eufe::Drone*>([value pointerValue]);
			ship->removeDrone(drone);
			n--;
		}
	}
	else {
		NSInteger n = sourceViewController.amount - drones.count;
		eufe::Drone* drone = reinterpret_cast<eufe::Drone*>([drones[0] pointerValue]);
		for (int i = 0; i < n; i++) {
			eufe::Drone* newDrone = ship->addDrone(drone->getTypeID());
			newDrone->setActive(drone->isActive());
			newDrone->setTarget(drone->getTarget());
		}
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

- (IBAction) unwindFromImplantsImport:(UIStoryboardSegue*) segue {
	NCFittingImplantsImportViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedFit) {
		eufe::Character* character = self.fit.pilot;
		eufe::ImplantsList implants = character->getImplants();
		for (auto implant: implants)
			character->removeImplant(implant);
		for (NCLoadoutDataShipImplant* implant in [(NCLoadoutDataShip*) sourceViewController.selectedFit.loadout.data.data implants])
			character->addImplant(implant.typeID);
		
		eufe::BoostersList boosters = character->getBoosters();
		for (auto booster: boosters)
			character->removeBooster(booster);
		for (NCLoadoutDataShipBooster* booster in [(NCLoadoutDataShip*) sourceViewController.selectedFit.loadout.data.data boosters])
			character->addBooster(booster.typeID);

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

@end

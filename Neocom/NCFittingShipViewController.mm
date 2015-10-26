//
//  NCFittingShipViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipViewController.h"
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
#import "NCFittingRequiredSkillsViewController.h"
#import "NCFittingImplantSetsViewController.h"
#import "NCFittingShipAffectingSkillsViewController.h"
#import "NCStoryboardPopoverSegue.h"
#import "UIColor+Neocom.h"
#import "NCShoppingItem+Neocom.h"
#import "NCShoppingGroup.h"
#import "NCNewShoppingItemViewController.h"

#import "NSString+Neocom.h"

#import "NCFittingShipModulesViewController.h"
#import "NCFittingShipDronesViewController.h"
#import "NCFittingShipImplantsViewController.h"
#import "NCFittingShipFleetViewController.h"
#import "NCFittingShipStatsViewController.h"
#import "NCAdaptivePopoverSegue.h"

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
#define ActionButtonAddToShoppingList NSLocalizedString(@"Add to Shopping List", nil)

@interface NCFittingShipViewController ()<MFMailComposeViewControllerDelegate>
@property (nonatomic, strong, readwrite) NSArray* fits;
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;

@property (nonatomic, weak) NCFittingShipModulesViewController* modulesViewController;
@property (nonatomic, weak) NCFittingShipDronesViewController* dronesViewController;
@property (nonatomic, weak) NCFittingShipImplantsViewController* implantsViewController;
@property (nonatomic, weak) NCFittingShipFleetViewController* fleetViewController;
@property (nonatomic, weak) NCFittingShipStatsViewController* statsViewController;
@property (nonatomic, strong) NCFitCharacter* defaultCharacter;

@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.sectionSegmentedControl removeSegmentAtIndex:self.sectionSegmentedControl.numberOfSegments - 1 animated:NO];
	
	self.taskManager.maxConcurrentOperationCount = 1;
	
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];

	for (id controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingShipModulesViewController class]])
			self.modulesViewController = controller;
		else if ([controller isKindOfClass:[NCFittingShipDronesViewController class]])
			self.dronesViewController = controller;
		else if ([controller isKindOfClass:[NCFittingShipImplantsViewController class]])
			self.implantsViewController = controller;
		else if ([controller isKindOfClass:[NCFittingShipFleetViewController class]])
			self.fleetViewController = controller;
		else if ([controller isKindOfClass:[NCFittingShipStatsViewController class]])
			self.statsViewController = controller;
	}

	NCFittingEngine* engine = [NCFittingEngine new];
	
	if (!self.fits)
		self.fits = @[self.fit];

	NCAccount* account = [NCAccount currentAccount];
	NCShipFit* fit = self.fit;
	dispatch_group_t finishDispatchGroup = dispatch_group_create();
	dispatch_group_enter(finishDispatchGroup);
	[engine performBlock:^{
		[engine loadShipFit:fit];
		dispatch_group_leave(finishDispatchGroup);
	}];
	__block NCFitCharacter* fitCharacter;
	
	void (^loadDefaultCharacter)() = ^{
		dispatch_group_enter(finishDispatchGroup);
		NSManagedObjectContext* storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
		[storageManagedObjectContext performBlock:^{
			fitCharacter = [storageManagedObjectContext fitCharacterWithSkillsLevel:5];
			dispatch_group_leave(finishDispatchGroup);
		}];
	};
	
	if (account) {
		dispatch_group_enter(finishDispatchGroup);
		[account loadFitCharacterWithCompletioBlock:^(NCFitCharacter *character) {
			if (character) {
				fitCharacter = character;
			}
			else
				loadDefaultCharacter();
			dispatch_group_leave(finishDispatchGroup);
		}];
	}
	else {
		loadDefaultCharacter();
	}
	
	dispatch_group_notify(finishDispatchGroup, dispatch_get_main_queue(), ^{
		[fit setCharacter:fitCharacter withCompletionBlock:^{
			self.defaultCharacter = fitCharacter;
			self.engine = engine;
			[self reload];
		}];
	});
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
//	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.sectionSegmentedControl.selectedSegmentIndex, 0);
}

- (void) viewWillDisappear:(BOOL)animated {
	if ([self isMovingFromParentViewController] || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		for (NCShipFit* fit in self.fits) {
			if (fit.loadoutID)
				[fit save];
		}
		self.fits = nil;
		if ([self.storageManagedObjectContext hasChanges])
			[self.storageManagedObjectContext save:nil];
	}
	[super viewWillDisappear:animated];
}

/*- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.sectionSegmentedControl.selectedSegmentIndex, 0);
	}
								 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
								 }];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.sectionSegmentedControl.selectedSegmentIndex, 0);
}*/

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //[super prepareForSegue:segue sender:sender];
    if ([segue isKindOfClass:[NCAdaptivePopoverSegue class]]) {
        NCAdaptivePopoverSegue* popoverSegue = (NCAdaptivePopoverSegue*) segue;
        if ([sender isKindOfClass:[NSDictionary class]])
            popoverSegue.sender = sender[@"sender"];
        else if ([sender isKindOfClass:[UIView class]])
            popoverSegue.sender = sender;
        else
            popoverSegue.sender = self.navigationItem.rightBarButtonItem;
    }

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
		auto item = [(NCFittingEngineItemPointer*) items[0] item];
		controller.items = items;
		
		auto module = std::dynamic_pointer_cast<eufe::Module>(item);
		auto drone = std::dynamic_pointer_cast<eufe::Drone>(item);
		
		std::shared_ptr<eufe::Ship> target = nullptr;
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

		[self.engine performBlockAndWait:^{
			auto item = [(NCFittingEngineItemPointer*) sender[@"object"] item];
			__block NSManagedObjectID* objectID;
			NSMutableDictionary* attributes = [NSMutableDictionary new];
			NCDBInvType* type = [self.engine.databaseManagedObjectContext invTypeWithTypeID:item->getTypeID()];
			
			for (NCDBDgmTypeAttribute* attribute in type.attributes) {
				attributes[@(attribute.attributeType.attributeID)] = @(item->getAttribute(attribute.attributeType.attributeID)->getValue());
			}
			objectID = [type objectID];
			controller.typeID = objectID;
			controller.attributes = attributes;
		}];
		
	}
	else if ([segue.identifier isEqualToString:@"NCFittingDamagePatternsViewController"]) {
		NCFittingDamagePatternsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
//		controller.selectedDamagePattern = self.damagePattern;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAreaEffectPickerViewController"]) {
		NCFittingAreaEffectPickerViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		auto area = self.engine.engine->getArea();
		if (area)
			controller.selectedAreaEffect = [self.databaseManagedObjectContext invTypeWithTypeID:area->getTypeID()];
	}
	else if ([segue.identifier isEqualToString:@"NCFittingTypeVariationsViewController"]) {
		NCFittingTypeVariationsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		[self.engine performBlockAndWait:^{
			NSArray* modules = sender[@"object"];
			controller.object = modules;
			auto item = [(NCFittingEngineItemPointer*) modules[0] item];
			__block NSManagedObjectID* objectID;
			[self.engine performBlockAndWait:^{
				NCDBInvType* type = [self.engine.databaseManagedObjectContext invTypeWithTypeID:item->getTypeID()];
				objectID = type.parentType ? [type.parentType objectID] : [type objectID];;
			}];
			controller.typeID = objectID;
		}];
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
		[self.engine performBlockAndWait:^{
			for (NCFittingEngineItemPointer* pointer in sender[@"object"]) {
				auto item = pointer.item;
				for (auto item: item->getAffectors()) {
					auto skill = std::dynamic_pointer_cast<eufe::Skill>(item);
					if (skill) {
						[typeIDs addObject:@(item->getTypeID())];
					}
				}
			}
		}];
		
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
		NSMutableArray* boosters = [NSMutableArray new];
		[self.engine performBlockAndWait:^{
			for (auto implant: self.fit.pilot->getImplants())
				[implants addObject:@(implant->getTypeID())];
			
			for (auto booster: self.fit.pilot->getBoosters())
				[boosters addObject:@(booster->getTypeID())];
		}];

		NCImplantSetData* data = [NCImplantSetData new];
		data.implantIDs = implants;
		data.boosterIDs = boosters;

		controller.implantSetData = data;
		controller.saveMode = YES;
	}
	else if ([segue.identifier isEqualToString:@"NCNewShoppingItemViewController"]) {
		NCNewShoppingItemViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.shoppingGroup = sender[@"object"];
	}
}

- (void) reload {
/*	[self.modulesViewController reload];
	[self.dronesViewController reload];
	[self.implantsViewController reload];
	[self.fleetViewController reload];
	[self.statsViewController reload];*/
	for (NCFittingShipWorkspaceViewController* controller in self.childViewControllers)
		[controller reload];
	
	if (!self.fit.pilot)
		return;

	[self.engine performBlock:^{
		float totalPG;
		float usedPG;
		float totalCPU;
		float usedCPU;
		float totalCalibration;
		float usedCalibration;
		
		float totalDB;
		float usedDB;
		float totalBandwidth;
		float usedBandwidth;
		int maxActiveDrones;
		int activeDrones;

		auto ship = self.fit.pilot->getShip();
		
		totalPG = ship->getTotalPowerGrid();
		usedPG = ship->getPowerGridUsed();
		totalCPU = ship->getTotalCpu();
		usedCPU = ship->getCpuUsed();
		totalCalibration = ship->getTotalCalibration();
		usedCalibration = ship->getCalibrationUsed();
		
		totalDB = ship->getTotalDroneBay();
		usedDB = ship->getDroneBayUsed();
		totalBandwidth = ship->getTotalDroneBandwidth();
		usedBandwidth = ship->getDroneBandwidthUsed();
		maxActiveDrones = ship->getMaxActiveDrones();
		activeDrones = ship->getActiveDrones();
		dispatch_async(dispatch_get_main_queue(), ^{
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			self.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			self.calibrationLabel.progress = totalCalibration > 0 ? usedCalibration / totalCalibration : 0;
			
			self.droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			self.droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			self.droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			self.droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			self.dronesCountLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				self.dronesCountLabel.textColor = [UIColor redColor];
			else
				self.dronesCountLabel.textColor = [UIColor whiteColor];
		});
	}];
}

- (void) removeFit:(NCShipFit *)fit {
	NSMutableArray* fits = [self.fits mutableCopy];
	[fits removeObject:fit];
	self.fits = [fits copy];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (IBAction)onChangeSection:(UISegmentedControl*)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * sender.selectedSegmentIndex, 0) animated:NO];
}

- (IBAction)onAction:(id)sender {
	if (!self.fit.pilot)
		return;
	
	NSMutableArray* actions = [NSMutableArray new];
	
	[self.engine performBlockAndWait:^{
		if (self.engine.engine->getArea() != NULL)
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonClearAreaEffect style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				[self.engine performBlockAndWait:^{
					self.engine.engine->clearArea();
				}];
				[self reload];
			}]];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowShipInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
									  sender:@{@"sender": sender, @"object": [NCFittingEngineItemPointer pointerWithItem:self.fit.pilot->getShip()]}];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSetName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
			__block UITextField* renameTextField;
			[controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
				renameTextField = textField;
				textField.text = self.fit.loadoutName;
				textField.clearButtonMode = UITextFieldViewModeAlways;
			}];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				self.fit.loadoutName = renameTextField.text;
				self.title = self.fit.loadoutName;
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			[self presentViewController:controller animated:YES completion:nil];
		}]];

		if (!self.fit.loadoutID)
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSave style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.fit save];
			}]];
		else
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonDuplicate style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//				[self.fit save];
//				self.fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
//				self.fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
//				self.fit.loadoutName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), self.fit.loadoutName ? self.fit.loadoutName : @""];
//				self.title = self.fit.loadoutName;
			}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonCharacter style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCFittingCharacterPickerViewController"
									  sender:@{@"sender": sender, @"object": self.fit}];
			[self reload];
		}]];
		
		/*if (self.fit.loadout.url)
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonViewInBrowser style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.fit.loadout.url]];
			}]];*/

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAreaEffect style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCFittingAreaEffectPickerViewController" sender:sender];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSetDamagePattern style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:sender];
		}]];

		NCAccount* account = [NCAccount currentAccount];
		if (account) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonRequiredSkills style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NCAccount* account = [NCAccount currentAccount];
				
				void (^load)(NCTrainingQueue*) = ^(NCTrainingQueue* trainingQueue) {
					__block std::set<eufe::TypeID> typeIDs;
					[self.engine performBlockAndWait:^{
						auto character = self.fit.pilot;
						auto ship = character->getShip();
						typeIDs.insert(ship->getTypeID());
						
						for (auto module: ship->getModules()) {
							typeIDs.insert(module->getTypeID());
							auto charge = module->getCharge();
							if (charge)
								typeIDs.insert(charge->getTypeID());
						}
						
						for (auto drone: ship->getDrones())
							typeIDs.insert(drone->getTypeID());
						
						for (auto implant: character->getImplants())
							typeIDs.insert(implant->getTypeID());
						
						for (auto booster: character->getBoosters())
							typeIDs.insert(booster->getTypeID());
					}];
					
					for (auto typeID: typeIDs)
						[trainingQueue addRequiredSkillsForType:[self.databaseManagedObjectContext invTypeWithTypeID:typeID]];
					[self performSegueWithIdentifier:@"NCFittingRequiredSkillsViewController"
											  sender:@{@"sender": sender, @"object": trainingQueue}];
				};
				
				if (account) {
					[[NCAccount currentAccount] loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
						dispatch_async(dispatch_get_main_queue(), ^{
							NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:self.databaseManagedObjectContext];
							load(trainingQueue);
						});
					}];
				}
				else
					load([NCTrainingQueue new]);
			}]];
		}
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonExport style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performExport];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAffectingSkills style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.engine performBlock:^{
				NSMutableDictionary* items = [NSMutableDictionary new];
				void (^addItem)(std::shared_ptr<eufe::Item>) = ^(std::shared_ptr<eufe::Item> item) {
					if (!items[@(item->getTypeID())])
						items[@(item->getTypeID())] = [NCFittingEngineItemPointer pointerWithItem:item];
				};
				auto pilot = self.fit.pilot;
				auto ship = pilot->getShip();
				addItem(ship);
				for (auto module: ship->getModules()) {
					addItem(module);
					auto charge = module->getCharge();
					if (charge)
						addItem(charge);
				}
				for (auto drone: ship->getDrones())
					addItem(drone);
				for (auto implant: pilot->getImplants())
					addItem(implant);
				for (auto booster: pilot->getBoosters())
					addItem(booster);
				dispatch_async(dispatch_get_main_queue(), ^{
					[self performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
											  sender:@{@"sender": sender, @"object": [items allValues]}];
				});
 			}];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAddToShoppingList style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSMutableDictionary* items = [NSMutableDictionary new];
			
			auto character = self.fit.pilot;
			
			NCShoppingGroup* shoppingGroup = [[NCShoppingGroup alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingGroup" inManagedObjectContext:self.storageManagedObjectContext]
													  insertIntoManagedObjectContext:nil];
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
			shoppingGroup.name = self.fit.loadoutName > 0 ? self.fit.loadoutName : type.typeName;
			shoppingGroup.quantity = 1;
			
			
			void (^addItem)(std::shared_ptr<eufe::Item>, int32_t) = ^(std::shared_ptr<eufe::Item> item, int32_t quanity) {
				NCShoppingItem* shoppingItem = items[@(item->getTypeID())];
				if (!shoppingItem) {
					shoppingItem = [[NCShoppingItem alloc] initWithTypeID:item->getTypeID() quantity:quanity entity:[NSEntityDescription entityForName:@"ShoppingItem" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:nil];
					shoppingItem.shoppingGroup = shoppingGroup;
					[shoppingGroup addShoppingItemsObject:shoppingItem];
					if (shoppingItem)
						items[@(item->getTypeID())] = shoppingItem;
				}
				else
					shoppingItem.quantity += quanity;
			};
			
			[self.engine performBlockAndWait:^{
				auto ship = character->getShip();
				addItem(ship, 1);
				
				for (auto module: ship->getModules()) {
					if (module->getSlot() == eufe::Module::SLOT_MODE)
						continue;
					
					addItem(module, 1);
					
					auto charge = module->getCharge();
					if (charge) {
						int n = module->getCharges();
						if (n == 0)
							n = 1;
						addItem(charge, n);
					}
				}
				
				for (auto drone: ship->getDrones())
					addItem(drone, 1);
			}];
			
			
			shoppingGroup.identifier = [shoppingGroup defaultIdentifier];
			shoppingGroup.immutable = YES;
			shoppingGroup.iconFile = type.icon.iconFile;
			
			[self performSegueWithIdentifier:@"NCNewShoppingItemViewController" sender:@{@"sender": sender, @"object": shoppingGroup}];
		}]];

	}];
	
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (UIAlertAction* action in actions)
		[controller addAction:action];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		if ([sender isKindOfClass:[UIBarButtonItem class]])
			controller.popoverPresentationController.barButtonItem = sender;
		else {
			controller.popoverPresentationController.sourceView = sender;
			controller.popoverPresentationController.sourceRect = [sender bounds];
		}
	}
	else
		[self presentViewController:controller animated:YES completion:nil];
}

- (void) setFit:(NCShipFit *)fit {
	_fit = fit;
	self.title = fit.loadoutName;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissAnimated];
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.tracking) {
		NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
		page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
		self.sectionSegmentedControl.selectedSegmentIndex = page;
	}
	else if (!scrollView.tracking && !scrollView.decelerating) {
		for (NCFittingShipWorkspaceViewController* controller in self.childViewControllers) {
			if ([controller isKindOfClass:[NCFittingShipWorkspaceViewController class]])
				[controller updateVisibility];
		}
	}
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
	self.sectionSegmentedControl.selectedSegmentIndex = page;
	for (NCFittingShipWorkspaceViewController* controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingShipWorkspaceViewController class]])
			[controller updateVisibility];
	}
}

#pragma mark - Private

- (IBAction) unwindFromCharacterPicker:(UIStoryboardSegue*) segue {
	NCFittingCharacterPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedCharacter) {
		if (sourceViewController.selectedCharacter.managedObjectContext)
			[sourceViewController.fit setCharacter:[self.storageManagedObjectContext existingObjectWithID:sourceViewController.selectedCharacter.objectID error:nil] withCompletionBlock:^{
				[self reload];
			}];
		else
			[sourceViewController.fit setCharacter:sourceViewController.selectedCharacter withCompletionBlock:^{
				[self reload];
			}];
	}
}

- (IBAction) unwindFromFitPicker:(UIStoryboardSegue*) segue {
	NCFittingFitPickerViewController* sourceViewController = segue.sourceViewController;
	NCShipFit* fit = sourceViewController.selectedFit;
	if (!fit)
		return;
	[self.engine performBlock:^{
		[self.engine loadShipFit:fit];
		NSArray* fits = [self.fits arrayByAddingObject:fit];
		[fit setCharacter:self.defaultCharacter withCompletionBlock:^{
			self.fits = fits;
			[self reload];
		}];
	}];
}

- (IBAction) unwindFromTargets:(UIStoryboardSegue*) segue {
	NCFittingTargetsViewController* sourceViewController = segue.sourceViewController;
	auto target = sourceViewController.selectedTarget ? sourceViewController.selectedTarget.pilot->getShip() : nullptr;
	[self.engine performBlockAndWait:^{
		for (NCFittingEngineItemPointer* pointer in sourceViewController.items) {
			std::shared_ptr<eufe::Module> module = std::dynamic_pointer_cast<eufe::Module>(pointer.item);
			std::shared_ptr<eufe::Drone> drone = std::dynamic_pointer_cast<eufe::Drone>(pointer.item);
			
			if (module)
				module->setTarget(target);
			else if (drone)
				drone->setTarget(target);
		}
	}];
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
		
//		self.damagePattern = sourceViewController.selectedDamagePattern;
		[self.engine performBlockAndWait:^{
			for (NCShipFit* fit in self.fits) {
				auto ship = fit.pilot->getShip();
				ship->setDamagePattern(damagePattern);
			}
		}];
		[self reload];
	}
}

- (IBAction) unwindFromAreaEffectPicker:(UIStoryboardSegue*) segue {
	NCFittingAreaEffectPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedAreaEffect) {
		[self.engine performBlockAndWait:^{
			self.engine.engine->setArea(sourceViewController.selectedAreaEffect.typeID);
		}];
		[self reload];
	}
}

- (IBAction) unwindFromTypeVariations:(UIStoryboardSegue*) segue {
	NCFittingTypeVariationsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedType) {
		auto ship = self.fit.pilot->getShip();
		eufe::TypeID typeID = sourceViewController.selectedType.typeID;

		[self.engine performBlockAndWait:^{
			for (NCFittingEngineItemPointer* pointer in sourceViewController.object) {
				auto module = std::dynamic_pointer_cast<eufe::Module>(pointer.item);
				if (module)
					ship->replaceModule(module, typeID);
			}
		}];
		[self reload];
	}
}

- (IBAction) unwindFromImplantSets:(UIStoryboardSegue*) segue {
	NCFittingImplantSetsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedImplantSet) {
		NSArray* implantIDs = [(NCImplantSetData*) sourceViewController.selectedImplantSet.data implantIDs];
		NSArray* boosterIDs = [(NCImplantSetData*) sourceViewController.selectedImplantSet.data boosterIDs];
		[self.engine performBlock:^{
			auto character = self.fit.pilot;
			eufe::ImplantsList implants = character->getImplants();
			for (auto implant: implants)
				character->removeImplant(implant);
			for (NSNumber* typeID in implantIDs)
				character->addImplant([typeID intValue]);
			
			eufe::BoostersList boosters = character->getBoosters();
			for (auto booster: boosters)
				character->removeBooster(booster);
			for (NSNumber* typeID in boosterIDs)
				character->addBooster([typeID intValue]);
			dispatch_async(dispatch_get_main_queue(), ^{
				[self reload];
			});
		}];
	}
}

- (IBAction) unwindFromAffectingSkills:(UIStoryboardSegue*) segue {
	NCFittingShipAffectingSkillsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.modified) {
		[[self fit] setCharacter:sourceViewController.character withCompletionBlock:^{
			[self reload];
		}];
	}
}

- (IBAction) unwindFromNewShoppingItem:(UIStoryboardSegue*)segue {
	
}

- (void) performExport {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy Link", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NSString* dna = self.fit.dnaRepresentation;
		[[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"http://neocom.by/api/fitting?dna=%@", [dna stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy DNA", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"fitting:%@", self.fit.dnaRepresentation]];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy EFT", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIPasteboard generalPasteboard] setString:self.fit.eftRepresentation];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy EVE XML", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIPasteboard generalPasteboard] setString:self.fit.eveXMLRepresentation];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open EVE XML in ...", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
		NSData* data = [[self.fit eveXMLRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
		NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.xml", type.typeName, self.fit.loadoutName]];
		[data writeToFile:path atomically:YES];
		self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
		[self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open EFT in ...", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
		NSData* data = [[self.fit eftRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
		NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.cfg", type.typeName, self.fit.loadoutName]];
		[data writeToFile:path atomically:YES];
		self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
		[self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
	}]];
	
	if ([MFMailComposeViewController canSendMail])
		[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Email", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
			NSString* tag = self.fit.hyperlinkTag;
			NSMutableString* message = [NSMutableString stringWithFormat:@"%@\n<pre>\n%@\n</pre>Generated by <a href=\"https://itunes.apple.com/us/app/neocom/id418895101?mt=8\">Neocom</a>", tag, self.fit.eftRepresentation];
			MFMailComposeViewController* controller = [MFMailComposeViewController new];
			[controller setSubject:[NSString stringWithFormat:@"%@ - %@", type.typeName, self.fit.loadoutName]];
			[controller setMessageBody:message isHTML:YES];
			[controller addAttachmentData:[self.fit.eveXMLRepresentation dataUsingEncoding:NSUTF8StringEncoding]
								 mimeType:@"application/xml"
								 fileName:[NSString stringWithFormat:@"%@.xml", self.fit.loadoutName]];
			controller.mailComposeDelegate = self;
			[self presentViewController:controller animated:YES completion:nil];
		}]];

	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		controller.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
	}
	else
		[self presentViewController:controller animated:YES completion:nil];
}

@end

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
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"
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
@property (nonatomic, strong, readwrite) NSMutableArray* fits;
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Engine> engine;

@property (nonatomic, weak) NCFittingShipModulesViewController* modulesViewController;
@property (nonatomic, weak) NCFittingShipDronesViewController* dronesViewController;
@property (nonatomic, weak) NCFittingShipImplantsViewController* implantsViewController;
@property (nonatomic, weak) NCFittingShipFleetViewController* fleetViewController;
@property (nonatomic, weak) NCFittingShipStatsViewController* statsViewController;

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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.sectionSegmentedControl removeSegmentAtIndex:self.sectionSegmentedControl.numberOfSegments - 1 animated:NO];
	
	self.taskManager.maxConcurrentOperationCount = 1;
	
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	

	
	if (!self.engine)
		self.engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	
	if (!self.fits)
		self.fits = [[NSMutableArray alloc] initWithObjects:self.fit, nil];
	NCShipFit* fit = self.fit;
	
	std::shared_ptr<eufe::Engine> engine = self.engine;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
//											 @synchronized(self) {
												 if (!fit.pilot) {
													 fit.pilot = engine->getGang()->addPilot();
													 NCAccount* account = [NCAccount currentAccount];
													 NCFitCharacter* character;
													 
													 if (account.characterSheet)
														 character = [[NCStorage sharedStorage] characterWithAccount:account];
													 else
														 character = [[NCStorage sharedStorage] characterWithSkillsLevel:5];
													 
													 fit.character = character;
													 [fit load];
												 }
//											 }
										 }
							 completionHandler:^(NCTask *task) {
								 [self reload];
							 }];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	for (id controller in self.childViewControllers) {
		if (![(UIViewController*) controller view].window)
			continue;
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
	[self reload];
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
			if (fit.loadout)
				[fit save];
		}
		self.fits = nil;
		[[NCStorage sharedStorage] saveContext];
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
		NCDBInvType* type = [self typeWithItem:item];
		
		NSMutableDictionary* attributes = [NSMutableDictionary new];
		for (NCDBDgmTypeAttribute* attribute in type.attributes) {
			attributes[@(attribute.attributeType.attributeID)] = @(item->getAttribute(attribute.attributeType.attributeID)->getValue());
		}
		
		controller.type = (id) type;
		controller.attributes = attributes;
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
			controller.selectedAreaEffect = [NCDBInvType invTypeWithTypeID:area->getTypeID()];
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
		NCDBInvType* type = [self typeWithItem:item];
		controller.type = type.parentType ? type.parentType : type;
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
	else if ([segue.identifier isEqualToString:@"NCNewShoppingItemViewController"]) {
		NCNewShoppingItemViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		controller.shoppingGroup = sender;
	}
}

- (NCDBInvType*) typeWithItem:(eufe::Item*) item {
	if (!item)
		return nil;
	@synchronized(self) {
		if (!self.typesCache)
			self.typesCache = [NSMutableDictionary new];
	}
	int typeID = item->getTypeID();
	
	NCDBInvType* type;
	@synchronized(self) {
		type = self.typesCache[@(typeID)];
	}
	if (!type) {
		type = [NCDBInvType invTypeWithTypeID:typeID];
		if (type) {
			@synchronized(self) {
				self.typesCache[@(typeID)] = type;
			}
		}
	}
	return type;
}

- (void) reload {
	[self.modulesViewController reload];
	[self.dronesViewController reload];
	[self.implantsViewController reload];
	[self.fleetViewController reload];
	[self.statsViewController reload];
	
	if (!self.fit.pilot)
		return;

	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	__block float totalCalibration;
	__block float usedCalibration;
	
	__block float totalDB;
	__block float usedDB;
	__block float totalBandwidth;
	__block float usedBandwidth;
	__block int maxActiveDrones;
	__block int activeDrones;
	

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 eufe::Ship* ship = self.fit.pilot->getShip();
											 
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

										 }
							 completionHandler:^(NCTask *task) {
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
							 }];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (IBAction)onChangeSection:(UISegmentedControl*)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * sender.selectedSegmentIndex, 0) animated:YES];
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
		[[NCStorage sharedStorage] saveContext];
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
												 //@synchronized(self) {
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
														 [trainingQueue addRequiredSkillsForType:[NCDBInvType invTypeWithTypeID:typeID]];
												 //}
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
	
	void (^addToShoppingList)() = ^() {
		NSMutableDictionary* items = [NSMutableDictionary new];
		
		eufe::Character* character = self.fit.pilot;
		eufe::Ship* ship = character->getShip();
		
		NCShoppingGroup* shoppingGroup = [[NCShoppingGroup alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingGroup" inManagedObjectContext:[[NCStorage sharedStorage] managedObjectContext]]
												  insertIntoManagedObjectContext:nil];
		shoppingGroup.name = self.fit.loadout.name.length > 0 ? self.fit.loadout.name : self.fit.type.typeName;
		shoppingGroup.quantity = 1;
		

		void (^addItem)(eufe::Item*, int32_t) = ^(eufe::Item* item, int32_t quanity) {
			NCShoppingItem* shoppingItem = items[@(item->getTypeID())];
			if (!shoppingItem) {
				shoppingItem = [NCShoppingItem shoppingItemWithType:[self typeWithItem:item] quantity:quanity];
				shoppingItem.shoppingGroup = shoppingGroup;
				[shoppingGroup addShoppingItemsObject:shoppingItem];
				if (shoppingItem)
					items[@(item->getTypeID())] = shoppingItem;
			}
			else
				shoppingItem.quantity += quanity;
		};
		
		addItem(ship, 1);
		
		for (auto module: ship->getModules()) {
			if (module->getSlot() == eufe::Module::SLOT_MODE)
				continue;
			
			addItem(module, 1);

			eufe::Charge* charge = module->getCharge();
			if (charge) {
				int n = module->getCharges();
				if (n == 0)
					n = 1;
				addItem(charge, n);
			}
		}
		
		for (auto drone: ship->getDrones())
			addItem(drone, 1);
		
		
		shoppingGroup.identifier = [shoppingGroup defaultIdentifier];
		shoppingGroup.immutable = YES;
		shoppingGroup.iconFile = self.fit.loadout.type.icon.iconFile;
		
		[self performSegueWithIdentifier:@"NCNewShoppingItemViewController" sender:shoppingGroup];
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

	[buttons addObject:ActionButtonAddToShoppingList];
	[actions addObject:addToShoppingList];

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

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.tracking) {
		NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
		page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
		self.sectionSegmentedControl.selectedSegmentIndex = page;
	}
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
	self.sectionSegmentedControl.selectedSegmentIndex = page;
}

#pragma mark - Private

- (IBAction) unwindFromCharacterPicker:(UIStoryboardSegue*) segue {
	NCFittingCharacterPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedCharacter)
		sourceViewController.fit.character = sourceViewController.selectedCharacter;
	else if ([sourceViewController.fit.character isDeleted]) {
		sourceViewController.fit.character = [[NCStorage sharedStorage] characterWithSkillsLevel:5];
	}
	[self reload];
}

- (IBAction) unwindFromFitPicker:(UIStoryboardSegue*) segue {
	NCFittingFitPickerViewController* sourceViewController = segue.sourceViewController;
	NCShipFit* fit = sourceViewController.selectedFit;
	if (!fit)
		return;
	std::shared_ptr<eufe::Engine> engine = self.engine;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (!fit.pilot) {
													 fit.pilot = engine->getGang()->addPilot();
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

- (IBAction) unwindFromNewShoppingItem:(UIStoryboardSegue*)segue {
	
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
																					if (!error) {
																						[[UIPasteboard generalPasteboard] setString:shortenLink];
																						[[UIAlertView alertViewWithTitle:nil
																												 message:NSLocalizedString(@"Link has been copied to clipboard", nil)
																									   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
																									   otherButtonTitles:nil
																										 completionBlock:nil
																											 cancelBlock:nil] show];
																					}
																					else {
																						[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Error", nil)
																												 message:[error localizedDescription]
																									   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
																									   otherButtonTitles:nil
																										 completionBlock:nil
																											 cancelBlock:nil] show];
																					}
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

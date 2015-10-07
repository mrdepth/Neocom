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
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;

@property (nonatomic, weak) NCFittingShipModulesViewController* modulesViewController;
@property (nonatomic, weak) NCFittingShipDronesViewController* dronesViewController;
@property (nonatomic, weak) NCFittingShipImplantsViewController* implantsViewController;
@property (nonatomic, weak) NCFittingShipFleetViewController* fleetViewController;
@property (nonatomic, weak) NCFittingShipStatsViewController* statsViewController;

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

	NCFittingEngine* engine = [NCFittingEngine new];

	if (!self.fits)
		self.fits = [[NSMutableArray alloc] initWithObjects:self.fit, nil];
	
	for (id controller in self.childViewControllers) {
//		if (![(UIViewController*) controller view].window)
//			continue;
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

	
	NCAccount* account = [NCAccount currentAccount];
	[engine performBlock:^{
		[engine loadShipFit:self.fit];
		
		void (^loadDefaultCharacter)() = ^{
			[self.storageManagedObjectContext performBlock:^{
				NCFitCharacter* character = [self.storageManagedObjectContext characterWithSkillsLevel:5];
				self.fit.character = character;
				dispatch_async(dispatch_get_main_queue(), ^{
					self.engine = engine;
					[self reload];
				});
			}];
		};
		
		if (account) {
			[account loadFitCharacterWithCompletioBlock:^(NCFitCharacter *fitCharacter) {
				if (fitCharacter) {
					self.fit.character = fitCharacter;
					dispatch_async(dispatch_get_main_queue(), ^{
						self.engine = engine;
						[self reload];
					});
				}
				else
					loadDefaultCharacter();
			}];
		}
		else {
			loadDefaultCharacter();
		}
	}];
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
			if (fit.loadout)
				[fit save];
		}
		self.fits = nil;
		[self.storageManagedObjectContext performBlock:^{
			if ([self.storageManagedObjectContext hasChanges])
				[self.storageManagedObjectContext save:nil];
		}];
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

		auto item = [(NCFittingEngineItemPointer*) sender[@"object"] item];
		NCDBInvType* type = [self.engine invTypeWithTypeID:item->getTypeID()];
		
		NSMutableDictionary* attributes = [NSMutableDictionary new];
		[self.engine performBlockAndWait:^{
			for (NCDBDgmTypeAttribute* attribute in type.attributes) {
				attributes[@(attribute.attributeType.attributeID)] = @(item->getAttribute(attribute.attributeType.attributeID)->getValue());
			}
		}];
		
		controller.typeID = [type objectID];
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
		NSArray* modules = sender[@"object"];
		controller.object = modules;
		auto item = [(NCFittingEngineItemPointer*) modules[0] item];
		NCDBInvType* type = [self.engine invTypeWithTypeID:item->getTypeID()];
		controller.typeID = type.parentType ? [type.parentType objectID] : [type objectID];
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
		auto item = [(NCFittingEngineItemPointer*) sender[@"object"] item];
		for (auto item: item->getAffectors()) {
			auto skill = std::dynamic_pointer_cast<eufe::Skill>(item);
			if (skill) {
				[typeIDs addObject:@(item->getTypeID())];
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
		controller.shoppingGroup = sender[@"object"];
	}
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
	

	[self.engine performBlockAndWait:^{
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
	}];
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
	if (!self.fit.character)
		return;
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^clearAreaEffect)() = ^() {
		self.engine.engine->clearArea();
		[self reload];
	};
	
	void (^shipInfo)() = ^() {
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
								  sender:@{@"sender": sender, @"object": [NCFittingEngineItemPointer pointerWithItem:self.fit.pilot->getShip()]}];
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
		self.fit.loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
		self.fit.loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
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
		[[NCAccount currentAccount] loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NCTrainingQueue* trainingQueue = [[NCTrainingQueue alloc] initWithCharacterSheet:characterSheet databaseManagedObjectContext:self.databaseManagedObjectContext];
				std::set<eufe::TypeID> typeIDs;
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
				
				for (auto typeID: typeIDs)
					[trainingQueue addRequiredSkillsForType:[self.databaseManagedObjectContext invTypeWithTypeID:typeID]];
				[self performSegueWithIdentifier:@"NCFittingRequiredSkillsViewController"
										  sender:@{@"sender": sender, @"object": trainingQueue}];
			});
		}];
	};
	
	void (^exportFit)() = ^() {
		[self performExport];
	};
	
	void (^affectingSkills)(eufe::ModulesList) = ^(eufe::ModulesList modules){
		[self performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
								  sender:@{@"sender": sender, @"object": [NCFittingEngineItemPointer pointerWithItem:self.fit.pilot->getShip()]}];
	};
	
	void (^addToShoppingList)() = ^() {
		NSMutableDictionary* items = [NSMutableDictionary new];
		
		auto character = self.fit.pilot;
		auto ship = character->getShip();
		
		NCShoppingGroup* shoppingGroup = [[NCShoppingGroup alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingGroup" inManagedObjectContext:self.storageManagedObjectContext]
												  insertIntoManagedObjectContext:nil];
		NCDBInvType* type = [self.engine invTypeWithTypeID:self.fit.typeID];
		shoppingGroup.name = self.fit.loadout.name.length > 0 ? self.fit.loadoutName : type.typeName;
		shoppingGroup.quantity = 1;
		

		void (^addItem)(std::shared_ptr<eufe::Item>, int32_t) = ^(std::shared_ptr<eufe::Item> item, int32_t quanity) {
			NCShoppingItem* shoppingItem = items[@(item->getTypeID())];
			if (!shoppingItem) {
				shoppingItem = [[NCShoppingItem alloc] initWithTypeID:item->getTypeID() quantity:quanity entity:[NSEntityDescription entityForName:@"ShoppingImage" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:nil];
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
		
		
		shoppingGroup.identifier = [shoppingGroup defaultIdentifier];
		shoppingGroup.immutable = YES;
		shoppingGroup.iconFile = type.icon.iconFile;
		
		[self performSegueWithIdentifier:@"NCNewShoppingItemViewController" sender:@{@"sender": sender, @"object": shoppingGroup}];
	};

	
	if (self.engine.engine->getArea() != NULL)
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
									destructiveButtonTitle:self.engine.engine->getArea() != NULL ? ActionButtonClearAreaEffect : nil
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
		sourceViewController.fit.character = [self.storageManagedObjectContext characterWithSkillsLevel:5];
	}
	[self reload];
}

- (IBAction) unwindFromFitPicker:(UIStoryboardSegue*) segue {
/*	NCFittingFitPickerViewController* sourceViewController = segue.sourceViewController;
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
							 }];*/
}

- (IBAction) unwindFromTargets:(UIStoryboardSegue*) segue {
	NCFittingTargetsViewController* sourceViewController = segue.sourceViewController;
	auto target = sourceViewController.selectedTarget ? sourceViewController.selectedTarget.pilot->getShip() : nullptr;

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
			auto ship = fit.pilot->getShip();
			ship->setDamagePattern(damagePattern);
		}
		[self reload];
	}
}

- (IBAction) unwindFromAreaEffectPicker:(UIStoryboardSegue*) segue {
	NCFittingAreaEffectPickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedAreaEffect) {
		self.engine.engine->setArea(sourceViewController.selectedAreaEffect.typeID);
		[self reload];
	}
}

- (IBAction) unwindFromTypeVariations:(UIStoryboardSegue*) segue {
	NCFittingTypeVariationsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedType) {
		auto ship = self.fit.pilot->getShip();
		eufe::TypeID typeID = sourceViewController.selectedType.typeID;

		for (NSValue* value in sourceViewController.object) {
			eufe::Module* module = reinterpret_cast<eufe::Module*>([value pointerValue]);
			ship->replaceModule(module->shared_from_this(), typeID);
		}
		[self reload];
	}
}

- (IBAction) unwindFromImplantSets:(UIStoryboardSegue*) segue {
	NCFittingImplantSetsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedImplantSet) {
		auto character = self.fit.pilot;
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
												   NCDBInvType* type = [self.engine invTypeWithTypeID:self.fit.typeID];
												   if (selectedButtonIndex == 0) {
													   NSString* dna = self.fit.dnaRepresentation;
													   [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"http://neocom.by/api/fitting?dna=%@", [dna stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
													   [[UIAlertView alertViewWithTitle:nil
																				message:NSLocalizedString(@"Link has been copied to clipboard", nil)
																	  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
																	  otherButtonTitles:nil
																		completionBlock:nil
																			cancelBlock:nil] show];
												   }
												   else if (selectedButtonIndex == 1)
													   [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"fitting:%@", self.fit.dnaRepresentation]];
												   else if (selectedButtonIndex == 2)
													   [[UIPasteboard generalPasteboard] setString:self.fit.eftRepresentation];
												   else if (selectedButtonIndex == 3)
													   [[UIPasteboard generalPasteboard] setString:self.fit.eveXMLRepresentation];
												   else if (selectedButtonIndex == 4) {
													   NSData* data = [[self.fit eveXMLRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
													   NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.xml", type.typeName, self.fit.loadoutName]];
													   [data writeToFile:path atomically:YES];
													   self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
													   [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
												   }
												   else if (selectedButtonIndex == 5) {
													   NSData* data = [[self.fit eftRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
													   NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - %@.cfg", type.typeName, self.fit.loadoutName]];
													   [data writeToFile:path atomically:YES];
													   self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
													   [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
												   }
												   else if (selectedButtonIndex == 6) {
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
												   }
											   }
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

@end

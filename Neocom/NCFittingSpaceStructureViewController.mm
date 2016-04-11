//
//  NCFittingSpaceStructureViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFittingSpaceStructureViewController.h"
#import "NCStorage.h"
#import "NCFitCharacter.h"
#import "NCAccount.h"
#import "NCFittingCharacterPickerViewController.h"
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
#import "NCFittingCRESTFitExportViewController.h"

#import "NSString+Neocom.h"

#import "NCFittingSpaceStructureModulesViewController.h"
#import "NCFittingSpaceStructureDronesViewController.h"
#import "NCFittingSpaceStructureImplantsViewController.h"
#import "NCFittingSpaceStructureStatsViewController.h"
#import "NCAdaptivePopoverSegue.h"

#import "UIAlertController+Neocom.h"

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
#define ActionButtonShowStructureInfo NSLocalizedString(@"Structure Info", nil)
#define ActionButtonAddToShoppingList NSLocalizedString(@"Add to Shopping List", nil)

@interface NCFittingSpaceStructureViewController ()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;

@property (nonatomic, weak) NCFittingSpaceStructureModulesViewController* modulesViewController;
//@property (nonatomic, weak) NCFittingSpaceStructureImplantsViewController* implantsViewController;
@property (nonatomic, weak) NCFittingSpaceStructureDronesViewController* dronesViewController;
@property (nonatomic, weak) NCFittingSpaceStructureStatsViewController* statsViewController;
@property (nonatomic, strong) NCFitCharacter* defaultCharacter;

@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

- (void) updateSectionSegmentedControlWithTraitCollection:(UITraitCollection*) traitCollection;
@end

@implementation NCFittingSpaceStructureViewController

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
		[self updateSectionSegmentedControlWithTraitCollection:self.traitCollection];
	//[self.sectionSegmentedControl removeSegmentAtIndex:self.sectionSegmentedControl.numberOfSegments - 1 animated:NO];
	BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
	if (disableSaveChangesPrompt)
		self.navigationItem.leftBarButtonItem = nil;
	
	self.taskManager.maxConcurrentOperationCount = 1;
	
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
	
	for (id controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingSpaceStructureModulesViewController class]])
			self.modulesViewController = controller;
		else if ([controller isKindOfClass:[NCFittingSpaceStructureDronesViewController class]])
			self.dronesViewController = controller;
		//else if ([controller isKindOfClass:[NCFittingSpaceStructureImplantsViewController class]])
		//	self.implantsViewController = controller;
		else if ([controller isKindOfClass:[NCFittingSpaceStructureStatsViewController class]])
			self.statsViewController = controller;
	}
	
	NCFittingEngine* engine = [NCFittingEngine new];
	
	NCAccount* account = [NCAccount currentAccount];
	NCSpaceStructureFit* fit = self.fit;
	dispatch_group_t finishDispatchGroup = dispatch_group_create();
	dispatch_group_enter(finishDispatchGroup);
	
	[engine performBlock:^{
		[engine loadSpaceStructureFit:fit];
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
	if ([self isMovingFromParentViewController] || !self.splitViewController) {
		BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
		if (disableSaveChangesPrompt) {
			if (self.fit.loadoutID)
				[self.fit save];
			self.fit = nil;
			if ([self.storageManagedObjectContext hasChanges])
				[self.storageManagedObjectContext save:nil];
		}
		else if (self.fit) {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Save Changes?", nil) preferredStyle:UIAlertControllerStyleAlert];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.fit save];
				self.fit = nil;
				if ([self.storageManagedObjectContext hasChanges])
					[self.storageManagedObjectContext save:nil];
			}]];
			
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Discard", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			}]];
			[[UIAlertController frontMostViewController] presentViewController:controller animated:YES completion:nil];
		}
	}
	[super viewWillDisappear:animated];
}

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
		controller.fits = @[self.fit];
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
				for (const auto& item: item->getAffectors()) {
					auto skill = std::dynamic_pointer_cast<dgmpp::Skill>(item);
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
			for (const auto& implant: self.fit.pilot->getImplants())
				[implants addObject:@(implant->getTypeID())];
			
			for (const auto& booster: self.fit.pilot->getBoosters())
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
	for (NCFittingSpaceStructureWorkspaceViewController* controller in self.childViewControllers)
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
		
		auto spaceStructure = self.fit.pilot->getSpaceStructure();
		
		totalPG = spaceStructure->getTotalPowerGrid();
		usedPG = spaceStructure->getPowerGridUsed();
		totalCPU = spaceStructure->getTotalCpu();
		usedCPU = spaceStructure->getCpuUsed();
		totalCalibration = spaceStructure->getTotalCalibration();
		usedCalibration = spaceStructure->getCalibrationUsed();
		
		totalDB = spaceStructure->getTotalDroneBay();
		usedDB = spaceStructure->getDroneBayUsed();
		totalBandwidth = spaceStructure->getTotalDroneBandwidth();
		usedBandwidth = spaceStructure->getDroneBandwidthUsed();
		maxActiveDrones = spaceStructure->getMaxActiveDrones();
		activeDrones = spaceStructure->getActiveDrones();
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
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowStructureInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
									  sender:@{@"sender": sender, @"object": [NCFittingEngineItemPointer pointerWithItem:self.fit.pilot->getSpaceStructure()]}];
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
				[self.fit duplicateWithCompletioBloc:^{
					self.title = self.fit.loadoutName;
				}];
			}]];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonCharacter style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCFittingCharacterPickerViewController"
									  sender:@{@"sender": sender, @"object": self.fit}];
			[self reload];
		}]];
		
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
					__block std::set<dgmpp::TypeID> typeIDs;
					[self.engine performBlockAndWait:^{
						auto character = self.fit.pilot;
						auto spaceStructure = character->getSpaceStructure();
						typeIDs.insert(spaceStructure->getTypeID());
						
						for (const auto& module: spaceStructure->getModules()) {
							typeIDs.insert(module->getTypeID());
							auto charge = module->getCharge();
							if (charge)
								typeIDs.insert(charge->getTypeID());
						}
						
						for (const auto& drone: spaceStructure->getDrones())
							typeIDs.insert(drone->getTypeID());
						
						for (const auto& implant: character->getImplants())
							typeIDs.insert(implant->getTypeID());
						
						for (const auto& booster: character->getBoosters())
							typeIDs.insert(booster->getTypeID());
					}];
					
					for (const auto& typeID: typeIDs)
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
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAddToShoppingList style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSMutableDictionary* items = [NSMutableDictionary new];
			
			auto character = self.fit.pilot;
			
			NCShoppingGroup* shoppingGroup = [[NCShoppingGroup alloc] initWithEntity:[NSEntityDescription entityForName:@"ShoppingGroup" inManagedObjectContext:self.storageManagedObjectContext]
													  insertIntoManagedObjectContext:nil];
			NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
			shoppingGroup.name = self.fit.loadoutName > 0 ? self.fit.loadoutName : type.typeName;
			shoppingGroup.quantity = 1;
			
			
			void (^addItem)(std::shared_ptr<dgmpp::Item>, int32_t) = ^(std::shared_ptr<dgmpp::Item> item, int32_t quanity) {
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
				auto spaceStructure = character->getSpaceStructure();
				addItem(spaceStructure, 1);
				
				for (const auto& module: spaceStructure->getModules()) {
					if (module->getSlot() == dgmpp::Module::SLOT_MODE)
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
				
				for (const auto& drone: spaceStructure->getDrones())
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

- (IBAction)onBack:(id)sender {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Save Changes?", nil) preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save and Exit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self.fit save];
		self.fit = nil;
		if ([self.storageManagedObjectContext hasChanges])
			[self.storageManagedObjectContext save:nil];
		[self.navigationController popViewControllerAnimated:YES];
	}]];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Discard and Exit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.fit = nil;
		[self.navigationController popViewControllerAnimated:YES];
	}]];
	
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	[self presentViewController:controller animated:YES completion:nil];
	
}

- (void) setFit:(NCSpaceStructureFit *)fit {
	_fit = fit;
	self.title = fit.loadoutName;
}

- (void) willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self updateSectionSegmentedControlWithTraitCollection:newCollection];
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
		for (NCFittingSpaceStructureWorkspaceViewController* controller in self.childViewControllers) {
			if ([controller isKindOfClass:[NCFittingSpaceStructureWorkspaceViewController class]])
				[controller updateVisibility];
		}
	}
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
	self.sectionSegmentedControl.selectedSegmentIndex = page;
	for (NCFittingSpaceStructureWorkspaceViewController* controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingSpaceStructureWorkspaceViewController class]])
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

- (IBAction) unwindFromDamagePatterns:(UIStoryboardSegue*) segue {
	NCFittingDamagePatternsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedDamagePattern) {
		dgmpp::DamagePattern damagePattern;
		damagePattern.emAmount = sourceViewController.selectedDamagePattern.em;
		damagePattern.thermalAmount = sourceViewController.selectedDamagePattern.thermal;
		damagePattern.kineticAmount = sourceViewController.selectedDamagePattern.kinetic;
		damagePattern.explosiveAmount = sourceViewController.selectedDamagePattern.explosive;
		
		//		self.damagePattern = sourceViewController.selectedDamagePattern;
		[self.engine performBlockAndWait:^{
			auto spaceStructure = self.fit.pilot->getSpaceStructure();
			if (spaceStructure)
				spaceStructure->setDamagePattern(damagePattern);
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
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[segue.sourceViewController dismissAnimated];
}

- (IBAction) unwindFromTypeVariations:(UIStoryboardSegue*) segue {
	NCFittingTypeVariationsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedType) {
		auto spaceStructure = self.fit.pilot->getSpaceStructure();
		dgmpp::TypeID typeID = sourceViewController.selectedType.typeID;
		
		[self.engine performBlockAndWait:^{
			for (NCFittingEngineItemPointer* pointer in sourceViewController.object) {
				auto module = std::dynamic_pointer_cast<dgmpp::Module>(pointer.item);
				if (module)
					spaceStructure->replaceModule(module, typeID);
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
			dgmpp::ImplantsList implants = character->getImplants();
			for (const auto& implant: implants)
				character->removeImplant(implant);
			for (NSNumber* typeID in implantIDs)
				character->addImplant([typeID intValue]);
			
			dgmpp::BoostersList boosters = character->getBoosters();
			for (const auto& booster: boosters)
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

- (IBAction) unwindFromCRESTFitExport:(UIStoryboardSegue*)segue {
	
}

- (void) updateSectionSegmentedControlWithTraitCollection:(UITraitCollection*) traitCollection {
	if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
		if (self.sectionSegmentedControl.numberOfSegments == 2)
			[self.sectionSegmentedControl insertSegmentWithTitle:NSLocalizedString(@"Stats", nil) atIndex:2 animated:NO];
	}
	else if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
		if (self.sectionSegmentedControl.numberOfSegments == 3)
			[self.sectionSegmentedControl removeSegmentAtIndex:2 animated:NO];
	}
}

@end

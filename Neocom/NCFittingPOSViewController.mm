//
//  NCFittingPOSViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSViewController.h"
#import "NCStorage.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingDamagePatternsViewController.h"
#import "NCStoryboardPopoverSegue.h"
#import "NCShoppingItem+Neocom.h"
#import "NCShoppingGroup.h"
#import "NCNewShoppingItemViewController.h"
#import "NCFittingPOSStructuresViewController.h"
#import "NCFittingPOSAssemblyLinesViewController.h"
#import "NCFittingPOSStatsViewController.h"
#import "NSString+Neocom.h"
#import "UIColor+Neocom.h"
#import "UIAlertController+Neocom.h"

#define ActionButtonShowControlTowerInfo NSLocalizedString(@"Control Tower Info", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonDuplicate NSLocalizedString(@"Duplicate Fit", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonAddToShoppingList NSLocalizedString(@"Add to Shopping List", nil)

@interface NCFittingPOSViewController ()
@property (nonatomic, strong, readwrite) NCFittingEngine* engine;

@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, weak) NCFittingPOSStructuresViewController* structuresViewController;
@property (nonatomic, weak) NCFittingPOSAssemblyLinesViewController* assemblyLinesViewController;
@property (nonatomic, weak) NCFittingPOSStatsViewController* statsViewController;
- (void) updateSectionSegmentedControlWithTraitCollection:(UITraitCollection*) traitCollection;

@end

@implementation NCFittingPOSViewController

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
//		[self.sectionSegmentedControl removeSegmentAtIndex:self.sectionSegmentedControl.numberOfSegments - 1 animated:NO];

	BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
	if (disableSaveChangesPrompt)
		self.navigationItem.leftBarButtonItem = nil;

	self.taskManager.maxConcurrentOperationCount = 1;
	self.title = self.fit.loadoutName;
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];

	for (id controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingPOSStructuresViewController class]])
			self.structuresViewController = controller;
		else if ([controller isKindOfClass:[NCFittingPOSAssemblyLinesViewController class]])
			self.assemblyLinesViewController = controller;
		else if ([controller isKindOfClass:[NCFittingPOSStatsViewController class]])
			self.statsViewController = controller;
	}

	
	NCFittingEngine* engine = [NCFittingEngine new];
	NCPOSFit* fit = self.fit;
	
	[engine performBlock:^{
		[engine loadPOSFit:fit];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.engine = engine;
			[self reload];
		});
	}];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.sectionSegmentedControl.selectedSegmentIndex, 0);
	}
								 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
								 }];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.sectionSegmentedControl.selectedSegmentIndex, 0);
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isKindOfClass:[NCStoryboardPopoverSegue class]]) {
		NCStoryboardPopoverSegue* popoverSegue = (NCStoryboardPopoverSegue*) segue;
		if ([sender isKindOfClass:[UIBarButtonItem class]])
			popoverSegue.anchorBarButtonItem = sender;
		else if ([sender isKindOfClass:[UIView class]])
			popoverSegue.anchorView = sender;
		else
			popoverSegue.anchorBarButtonItem = self.navigationItem.rightBarButtonItem;
	}

	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
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
	for (NCFittingPOSWorkspaceViewController* controller in self.childViewControllers)
		[controller reload];
	if (!self.fit.engine || !self.fit.engine.engine->getControlTower())
		return;
	
	[self.engine performBlock:^{
		float totalPG;
		float usedPG;
		float totalCPU;
		float usedCPU;
		
		auto controlTower = self.engine.engine->getControlTower();
		totalPG = controlTower->getTotalPowerGrid();
		usedPG = controlTower->getPowerGridUsed();
		
		totalCPU = controlTower->getTotalCpu();
		usedCPU = controlTower->getCpuUsed();

		dispatch_async(dispatch_get_main_queue(), ^{
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
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
	if (!self.fit.engine || !self.fit.engine.engine->getControlTower())
		return;
	
	NSMutableArray* actions = [NSMutableArray new];
	
	[self.engine performBlockAndWait:^{
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowControlTowerInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
									  sender:@{@"sender": sender, @"object": [NCFittingEngineItemPointer pointerWithItem:self.engine.engine->getControlTower()]}];
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
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonSetDamagePattern style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:sender];
		}]];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAddToShoppingList style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSMutableDictionary* items = [NSMutableDictionary new];
			
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
				auto controlTower = self.engine.engine->getControlTower();
				addItem(controlTower, 1);
				
				for (const auto& structure: controlTower->getStructures()) {
					addItem(structure, 1);
					
					auto charge = structure->getCharge();
					if (charge) {
						int n = structure->getCharges();
						if (n == 0)
							n = 1;
						addItem(charge, n);
					}
				}
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

- (void) willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self updateSectionSegmentedControlWithTraitCollection:newCollection];
}


#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.tracking) {
		NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
		page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
		self.sectionSegmentedControl.selectedSegmentIndex = page;
	}
	else if (!scrollView.tracking && !scrollView.decelerating) {
		for (NCFittingPOSWorkspaceViewController* controller in self.childViewControllers) {
			if ([controller isKindOfClass:[NCFittingPOSWorkspaceViewController class]])
				[controller updateVisibility];
		}
	}
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	NSInteger page = round(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	page = MAX(0, MIN(page, self.sectionSegmentedControl.numberOfSegments - 1));
	self.sectionSegmentedControl.selectedSegmentIndex = page;
	for (NCFittingPOSWorkspaceViewController* controller in self.childViewControllers) {
		if ([controller isKindOfClass:[NCFittingPOSWorkspaceViewController class]])
			[controller updateVisibility];
	}
}

#pragma mark - Private


- (IBAction) unwindFromDamagePatterns:(UIStoryboardSegue*) segue {
	NCFittingDamagePatternsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedDamagePattern) {
		dgmpp::DamagePattern damagePattern;
		damagePattern.emAmount = sourceViewController.selectedDamagePattern.em;
		damagePattern.thermalAmount = sourceViewController.selectedDamagePattern.thermal;
		damagePattern.kineticAmount = sourceViewController.selectedDamagePattern.kinetic;
		damagePattern.explosiveAmount = sourceViewController.selectedDamagePattern.explosive;
		
		//self.damagePattern = sourceViewController.selectedDamagePattern;
		auto controlTower = self.fit.engine.engine->getControlTower();
		[self.engine performBlockAndWait:^{
			controlTower->setDamagePattern(damagePattern);
			[self reload];
		}];
	}
}

- (IBAction) unwindFromNewShoppingItem:(UIStoryboardSegue*)segue {
	
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

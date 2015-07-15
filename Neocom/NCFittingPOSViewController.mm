//
//  NCFittingPOSViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSViewController.h"
#import "UIActionSheet+Block.h"
#import "UIAlertView+Block.h"
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

#define ActionButtonShowControlTowerInfo NSLocalizedString(@"Control Tower Info", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonDuplicate NSLocalizedString(@"Duplicate Fit", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonAddToShoppingList NSLocalizedString(@"Add to Shopping List", nil)

@interface NCFittingPOSViewController ()
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Engine> engine;

@property (nonatomic, strong) NSMutableDictionary* typesCache;
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) UIActionSheet* actionSheet;

@property (nonatomic, weak) NCFittingPOSStructuresViewController* structuresViewController;
@property (nonatomic, weak) NCFittingPOSAssemblyLinesViewController* assemblyLinesViewController;
@property (nonatomic, weak) NCFittingPOSStatsViewController* statsViewController;

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
		[self.sectionSegmentedControl removeSegmentAtIndex:self.sectionSegmentedControl.numberOfSegments - 1 animated:NO];

	self.taskManager.maxConcurrentOperationCount = 1;
	self.title = self.fit.loadoutName;
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];

	std::shared_ptr<eufe::Engine> engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	
	NCPOSFit* fit = self.fit;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (!fit.engine) {
													 fit.engine = engine.get();
													 [fit load];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.engine = engine;
								 [self reload];

							 }];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	for (id controller in self.childViewControllers) {
		if (![(UIViewController*) controller view].window)
			continue;
		if ([controller isKindOfClass:[NCFittingPOSStructuresViewController class]])
			self.structuresViewController = controller;
		else if ([controller isKindOfClass:[NCFittingPOSAssemblyLinesViewController class]])
			self.assemblyLinesViewController = controller;
		else if ([controller isKindOfClass:[NCFittingPOSStatsViewController class]])
			self.statsViewController = controller;
	}
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillDisappear:(BOOL)animated {
	if ([self isMovingFromParentViewController] || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.fit save];
		self.fit = nil;
		[[NCStorage sharedStorage] saveContext];
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
		
		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender pointerValue]);
		NCDBInvType* type = [self typeWithItem:item];
		
		[type.attributesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* attributeID, NCDBDgmTypeAttribute* attribute, BOOL *stop) {
			attribute.value = item->getAttribute(attribute.attributeType.attributeID)->getValue();
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
		int typeID = item->getTypeID();
		
		NCDBInvType* type = self.typesCache[@(typeID)];
		if (!type) {
			type = [NCDBInvType invTypeWithTypeID:typeID];
			if (type)
				self.typesCache[@(typeID)] = type;
		}
		return type;
	}
}

- (void) reload {
	[self.structuresViewController reload];
	[self.assemblyLinesViewController reload];
	[self.statsViewController reload];
	
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;

	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 eufe::ControlTower* controlTower = self.engine->getControlTower();
											 totalPG = controlTower->getTotalPowerGrid();
											 usedPG = controlTower->getPowerGridUsed();
											 
											 totalCPU = controlTower->getTotalCpu();
											 usedCPU = controlTower->getCpuUsed();

										 }
							 completionHandler:^(NCTask *task) {
								 self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
								 self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
								 self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
								 self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
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
	if (!self.fit.engine || !self.fit.engine->getControlTower())
		return;
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^controlTowerInfo)() = ^() {
		[self performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController" sender:[NSValue valueWithPointer:self.fit.engine->getControlTower()]];
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
	
	void (^setDamagePattern)() = ^() {
		[self performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:sender];
	};
	
	void (^addToShoppingList)() = ^() {
		NSMutableDictionary* items = [NSMutableDictionary new];
		
		eufe::ControlTower* controlTower = self.fit.engine->getControlTower();
		
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
		
		addItem(controlTower, 1);
		
		for (auto structure: controlTower->getStructures()) {
			addItem(structure, 1);
			
			eufe::Charge* charge = structure->getCharge();
			if (charge) {
				int n = structure->getCharges();
				if (n == 0)
					n = 1;
				addItem(charge, n);
			}
		}
		
		shoppingGroup.identifier = [shoppingGroup defaultIdentifier];
		shoppingGroup.immutable = YES;
		shoppingGroup.iconFile = self.fit.loadout.type.icon.iconFile;
		
		[self performSegueWithIdentifier:@"NCNewShoppingItemViewController" sender:shoppingGroup];
	};

	
	[actions addObject:controlTowerInfo];
	[buttons addObject:ActionButtonShowControlTowerInfo];
	
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
	
	[actions addObject:setDamagePattern];
	[buttons addObject:ActionButtonSetDamagePattern];
	
	[buttons addObject:ActionButtonAddToShoppingList];
	[actions addObject:addToShoppingList];

	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
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


- (IBAction) unwindFromDamagePatterns:(UIStoryboardSegue*) segue {
	NCFittingDamagePatternsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedDamagePattern) {
		eufe::DamagePattern damagePattern;
		damagePattern.emAmount = sourceViewController.selectedDamagePattern.em;
		damagePattern.thermalAmount = sourceViewController.selectedDamagePattern.thermal;
		damagePattern.kineticAmount = sourceViewController.selectedDamagePattern.kinetic;
		damagePattern.explosiveAmount = sourceViewController.selectedDamagePattern.explosive;
		
		self.damagePattern = sourceViewController.selectedDamagePattern;
		eufe::ControlTower* controlTower = self.fit.engine->getControlTower();
		controlTower->setDamagePattern(damagePattern);
		[self reload];
	}
}

- (IBAction) unwindFromNewShoppingItem:(UIStoryboardSegue*)segue {
	
}

@end

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
#import "NCFittingPOSStructuresDataSource.h"
#import "NCFittingPOSAssemblyLinesDataSource.h"
#import "NCFittingPOSStatsDataSource.h"
#import "NCStorage.h"
#import "NCDatabaseTypeInfoViewController.h"
#import "NCFittingAmountViewController.h"
#import "NCFittingDamagePatternsViewController.h"

#define ActionButtonShowControlTowerInfo NSLocalizedString(@"Control Tower Info", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonDuplicate NSLocalizedString(@"Duplicate Fit", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)

@interface NCFittingPOSViewController ()
@property (nonatomic, assign, readwrite) std::shared_ptr<eufe::Engine> engine;

@property (nonatomic, strong) NSMutableDictionary* typesCache;
@property (nonatomic, strong) NCFittingPOSStructuresDataSource* structuresDataSource;
@property (nonatomic, strong) NCFittingPOSAssemblyLinesDataSource* assemblyLinesDataSource;
@property (nonatomic, strong) NCFittingPOSStatsDataSource* statsDataSource;
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) UIActionSheet* actionSheet;

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
	self.title = self.fit.loadoutName;

	self.workspaceViewController = self.childViewControllers[0];
	
	if (!self.engine)
		self.engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	
	NCPOSFit* fit = self.fit;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (!fit.engine) {
													 fit.engine = self.engine.get();
													 [fit load];
												 }
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.structuresDataSource = [NCFittingPOSStructuresDataSource new];
								 self.structuresDataSource.controller = self;
								 self.structuresDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.assemblyLinesDataSource = [NCFittingPOSAssemblyLinesDataSource new];
								 self.assemblyLinesDataSource.controller = self;
								 self.assemblyLinesDataSource.tableView = self.workspaceViewController.tableView;
								 
								 self.statsDataSource = [NCFittingPOSStatsDataSource new];
								 self.statsDataSource.controller = self;
								 self.statsDataSource.tableView = self.workspaceViewController.tableView;
								 
								 
								 NCFittingPOSDataSource* dataSources[] = {self.structuresDataSource, self.assemblyLinesDataSource, self.statsDataSource};
								 NCFittingPOSDataSource* dataSource = dataSources[self.sectionSegmentedControl.selectedSegmentIndex];
								 
								 self.workspaceViewController.tableView.dataSource = dataSource;
								 self.workspaceViewController.tableView.delegate = dataSource;
								 self.workspaceViewController.tableView.tableHeaderView = dataSource.tableHeaderView;
								 [dataSource reload];

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
													 [self.fit save];
													 
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
	if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = [segue destinationViewController];
		eufe::Item* item = reinterpret_cast<eufe::Item*>([sender pointerValue]);
		EVEDBInvType* type = [self typeWithItem:item];
		
		[type.attributesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber* attributeID, EVEDBDgmTypeAttribute* attribute, BOOL *stop) {
			attribute.value = item->getAttribute(attribute.attributeID)->getValue();
		}];
		destinationViewController.type = type;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAmountViewController"]) {
		NSArray* structures = sender;
		NCFittingAmountViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.range = NSMakeRange(1, 50);
		controller.amount = structures.count;
		controller.object = structures;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingDamagePatternsViewController"]) {
		NCFittingDamagePatternsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.selectedDamagePattern = self.damagePattern;
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
	NCFittingPOSDataSource* dataSources[] = {self.structuresDataSource, self.assemblyLinesDataSource, self.statsDataSource};
	NCFittingPOSDataSource* dataSource = dataSources[self.sectionSegmentedControl.selectedSegmentIndex];
	
	self.workspaceViewController.tableView.dataSource = dataSource;
	self.workspaceViewController.tableView.delegate = dataSource;
	self.workspaceViewController.tableView.tableHeaderView = dataSource.tableHeaderView;
	[dataSource reload];
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

#pragma mark - Private


- (IBAction) unwindFromAmount:(UIStoryboardSegue*) segue {
	NCFittingAmountViewController* sourceViewController = segue.sourceViewController;
	NSArray* structures = sourceViewController.object;
	eufe::ControlTower* controlTower = self.fit.engine->getControlTower();
	if (structures.count > sourceViewController.amount) {
		NSInteger n = structures.count - sourceViewController.amount;
		for (NSValue* value in structures) {
			if (n <= 0)
				break;
			eufe::Structure* structure = reinterpret_cast<eufe::Structure*>([value pointerValue]);
			controlTower->removeStructure(structure);
			n--;
		}
	}
	else {
		NSInteger n = sourceViewController.amount - structures.count;
		eufe::Structure* structure = reinterpret_cast<eufe::Structure*>([structures[0] pointerValue]);
		for (int i = 0; i < n; i++) {
			eufe::Structure* newStructure = controlTower->addStructure(structure->getTypeID());
			newStructure->setState(structure->getState());
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
		eufe::ControlTower* controlTower = self.fit.engine->getControlTower();
		controlTower->setDamagePattern(damagePattern);
		[self reload];
	}
}

@end

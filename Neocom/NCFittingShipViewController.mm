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

#pragma mark - Private

- (IBAction) unwindFromCharacterPicker:(UIStoryboardSegue*) segue {
	NCFittingCharacterPickerViewController* sourceViewController = segue.sourceViewController;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 @synchronized(self) {
												 if (sourceViewController.selectedCharacter)
													 sourceViewController.fit.character = sourceViewController.selectedCharacter;
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

@end

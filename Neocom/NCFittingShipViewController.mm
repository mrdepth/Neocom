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

@interface NCFittingShipViewController ()
@property (nonatomic, strong) NCFittingShipModulesDataSource* modulesDataSource;
@property (nonatomic, strong) NCFittingShipDronesDataSource* dronesDataSource;
@property (nonatomic, strong) NCFittingShipImplantsDataSource* implantsDataSource;
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
	
	self.engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	self.character = self.engine->getGang()->addPilot();
	self.character->setShip(645)->addModule(11301);
	self.modulesDataSource = [NCFittingShipModulesDataSource new];
	self.modulesDataSource.controller = self;
	self.modulesDataSource.tableView = self.workspaceViewController.tableView;
	self.workspaceViewController.tableView.dataSource = self.modulesDataSource;
	self.workspaceViewController.tableView.delegate = self.modulesDataSource;
	self.workspaceViewController.tableView.tableHeaderView = self.modulesDataSource.tableHeaderView;
	
	self.dronesDataSource = [NCFittingShipDronesDataSource new];
	self.dronesDataSource.controller = self;
	self.dronesDataSource.tableView = self.workspaceViewController.tableView;
	
	self.implantsDataSource = [NCFittingShipImplantsDataSource new];
	self.implantsDataSource.controller = self;
	self.implantsDataSource.tableView = self.workspaceViewController.tableView;

	[self.modulesDataSource reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
	else {
		self.workspaceViewController.tableView.dataSource = self.implantsDataSource;
		self.workspaceViewController.tableView.delegate = self.implantsDataSource;
		self.workspaceViewController.tableView.tableHeaderView = self.implantsDataSource.tableHeaderView;
		[self.implantsDataSource reload];
	}
}

@end

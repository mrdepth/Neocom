//
//  NCFittingShipViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipViewController.h"
#import "NCFittingShipModulesDataSource.h"

@interface NCFittingShipViewController ()
@property (nonatomic, strong) NCFittingShipModulesDataSource* modulesDataSource;
@property (nonatomic, strong) NSMutableDictionary* typesCache;
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
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionGenericHedaerView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionGenericHedaerView"];
	self.engine = std::shared_ptr<eufe::Engine>(new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding])));
	self.character = self.engine->getGang()->addPilot();
	self.character->setShip(645)->addModule(11301);
	self.modulesDataSource = [NCFittingShipModulesDataSource new];
	self.modulesDataSource.controller = self;
	self.tableView.dataSource = self.modulesDataSource;
	self.tableView.delegate = self.modulesDataSource;
	[self.modulesDataSource reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (EVEDBInvType*) typeWithItem:(eufe::Item*) item {
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


@end

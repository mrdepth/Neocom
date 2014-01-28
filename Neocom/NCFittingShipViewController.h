//
//  NCFittingShipViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "eufe.h"
#import "NCStorage.h"

@interface NCFittingShipViewController : NCTableViewController
//@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, assign) std::shared_ptr<eufe::Engine> engine;
@property (nonatomic, strong) NCShipFit* fit;
@property (nonatomic, assign) eufe::Character* character;

- (EVEDBInvType*) typeWithItem:(eufe::Item*) item;

@end

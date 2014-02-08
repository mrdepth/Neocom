//
//  NCFittingImplantsImportViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 08.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCShipFit;
@interface NCFittingImplantsImportViewController : NCTableViewController
@property (nonatomic, strong) NCShipFit* selectedFit;
@end
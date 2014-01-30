//
//  NCFittingShipDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@class NCFittingShipViewController;
@class NCTask;
@interface NCFittingShipDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong, readonly) UIView* tableHeaderView;
@property (nonatomic, weak) UITableView* tableView;
@property (nonatomic, weak) NCFittingShipViewController* controller;

- (void) reload;

@end

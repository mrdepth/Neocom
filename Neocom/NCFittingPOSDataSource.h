//
//  NCFittingPOSDataSource.h
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVEDBAPI.h"

@class NCFittingPOSViewController;
@class NCTask;
@interface NCFittingPOSDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong, readonly) UIView* tableHeaderView;
@property (nonatomic, weak) UITableView* tableView;
@property (nonatomic, weak) NCFittingPOSViewController* controller;

- (void) reload;

@end

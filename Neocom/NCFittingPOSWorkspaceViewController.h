//
//  NCFittingPOSWorkspaceViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCFittingPOSViewController;
@interface NCFittingPOSWorkspaceViewController : NCTableViewController
@property (nonatomic, readonly) NCFittingPOSViewController* controller;

- (void) reload;

@end

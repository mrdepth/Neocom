//
//  NCFittingShipWorkspaceViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCFittingShipViewController;
@interface NCFittingShipWorkspaceViewController : NCTableViewController
@property (nonatomic, strong) UIImage* defaultTypeImage;
@property (nonatomic, strong) UIImage* targetImage;
@property (nonatomic, readonly) NCFittingShipViewController* controller;

- (void) reload;
- (void) reloadWithCompletionBlock:(void(^)()) completionBlock;
- (void) updateVisibility;
@end

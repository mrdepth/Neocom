//
//  NCFittingSpaceStructureWorkspaceViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCFittingSpaceStructureViewController;
@interface NCFittingSpaceStructureWorkspaceViewController : NCTableViewController
@property (nonatomic, strong) UIImage* defaultTypeImage;
@property (nonatomic, strong) UIImage* targetImage;
@property (nonatomic, readonly) NCFittingSpaceStructureViewController* controller;

- (void) reload;
- (void) reloadWithCompletionBlock:(void(^)()) completionBlock;
- (void) updateVisibility;
@end

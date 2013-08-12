//
//  FitsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingItemsViewController.h"
#import "FitsViewControllerDelegate.h"
#include "eufe.h"

@interface FitsViewController : UITableViewController
@property (nonatomic, weak) id<FitsViewControllerDelegate> delegate;
@property (nonatomic, assign) eufe::Engine* engine;


@end

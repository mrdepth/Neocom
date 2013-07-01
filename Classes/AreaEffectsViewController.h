//
//  AreaEffectsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AreaEffectsViewControllerDelegate.h"

@interface AreaEffectsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id<AreaEffectsViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIViewController *mainViewController;
@property (nonatomic, strong) EVEDBInvType* selectedArea;

@end

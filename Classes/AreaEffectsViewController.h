//
//  AreaEffectsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AreaEffectsViewControllerDelegate.h"

@interface AreaEffectsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate> {
	UITableView *tableView;
	id<AreaEffectsViewControllerDelegate> delegate;
	UIViewController *mainViewController;
	EVEDBInvType* selectedArea;
@protected
	NSMutableArray *sections;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet id<AreaEffectsViewControllerDelegate> delegate;
@property (nonatomic, assign) IBOutlet UIViewController *mainViewController;
@property (nonatomic, retain) EVEDBInvType* selectedArea;

@end

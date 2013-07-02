//
//  FilterViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewControllerDelegate.h"
#import "EUFilter.h"
#import "CollapsableTableView.h"

@interface FilterViewController : UITableViewController<CollapsableTableViewDelegate, UIPopoverControllerDelegate>
@property (nonatomic, weak) IBOutlet id<FilterViewControllerDelegate> delegate;
@property (nonatomic, strong) EUFilter *filter;
@property (nonatomic, strong) NSMutableArray *values;

- (IBAction) onDone:(id)sender;
- (IBAction) onCancel:(id)sender;

@end

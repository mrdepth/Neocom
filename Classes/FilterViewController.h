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

@interface FilterViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate> {
	UITableView *tableView;
	id<FilterViewControllerDelegate> delegate;
	EUFilter *filter;
	NSMutableArray *values;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet id<FilterViewControllerDelegate> delegate;
@property (nonatomic, retain) EUFilter *filter;
@property (nonatomic, retain) NSMutableArray *values;

- (IBAction) onDone:(id)sender;
- (IBAction) onCancel:(id)sender;

@end

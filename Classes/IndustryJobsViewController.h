//
//  IndustryJobsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"

@interface IndustryJobsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource> {
	UITableView *jobsTableView;
	UISegmentedControl *ownerSegmentControl;
	UISearchBar *searchBar;
	FilterViewController *filterViewController;
	UINavigationController *filterNavigationViewController;
	UIPopoverController *filterPopoverController;
@private
	NSMutableArray *filteredValues;
	NSMutableArray *jobs;
	NSMutableArray *charJobs;
	NSMutableArray *corpJobs;
	NSMutableDictionary *conquerableStations;
	EUFilter *charFilter;
	EUFilter *corpFilter;
}
@property (nonatomic, retain) IBOutlet UITableView *jobsTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *ownerSegmentControl;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;

- (IBAction) onChangeOwner:(id) sender;

@end

//
//  MarketInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEDBAPI.h"
#import "EVECentralAPI.h"

@interface MarketInfoViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl *reportTypeSegment;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UISearchDisplayController *searchDisplayController;
@property (nonatomic, weak) IBOutlet UIViewController *parentViewController;
@property (nonatomic, strong) EVEDBInvType *type;
@property (nonatomic, strong) NSArray *sellOrdersRegions;
@property (nonatomic, strong) NSArray *buyOrdersRegions;
@property (nonatomic, strong) NSArray *sellSummary;
@property (nonatomic, strong) NSArray *buySummary;

- (IBAction) onChangeReportTypeSegment: (id) sender;
@end

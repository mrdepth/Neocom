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

@interface MarketInfoViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate> {
	UITableView *ordersTableView;
	UISegmentedControl *reportTypeSegment;
	UISearchBar *searchBar;
	UISearchDisplayController *searchDisplayController;
	UIViewController *parentViewController;
	EVEDBInvType *type;
	NSArray *sellOrdersRegions;
	NSArray *buyOrdersRegions;
	NSArray *sellSummary;
	NSArray *buySummary;
	
@private
	NSMutableArray *filteredSellOrdersRegions;
	NSMutableArray *filteredBuyOrdersRegions;
	NSMutableArray *filteredSellSummary;
	NSMutableArray *filteredBuySummary;
}
@property (nonatomic, retain) IBOutlet UITableView *ordersTableView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *reportTypeSegment;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UISearchDisplayController *searchDisplayController;
@property (nonatomic, assign) IBOutlet UIViewController *parentViewController;
@property (nonatomic, retain) EVEDBInvType *type;
@property (nonatomic, retain) NSArray *sellOrdersRegions;
@property (nonatomic, retain) NSArray *buyOrdersRegions;
@property (nonatomic, retain) NSArray *sellSummary;
@property (nonatomic, retain) NSArray *buySummary;

- (IBAction) onChangeReportTypeSegment: (id) sender;
@end

//
//  EUSearchDisplayController.h
//  EVEUniverse
//
//  Created by Shimanski on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EUSearchDisplayController : UISearchDisplayController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UISearchBarDelegate> {
	UIPopoverController *popoverController;
	UITableViewController *tableViewController;
	UILabel *noResultsLabel;
	NSMutableArray *sections;
	UISegmentedControl *scopeSegmentControler;
}
@property (nonatomic, readonly, retain) UIPopoverController *popoverController;
@property (nonatomic, readonly, retain) UITableViewController *tableViewController;
@property (nonatomic, readonly, retain) UILabel *noResultsLabel;

- (IBAction) onChangePublishedFilterSegment: (id) sender;

@end

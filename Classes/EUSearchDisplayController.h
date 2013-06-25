//
//  EUSearchDisplayController.h
//  EVEUniverse
//
//  Created by Shimanski on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EUSearchDisplayController : UISearchDisplayController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UISearchBarDelegate>
@property (nonatomic, readonly, strong) UIPopoverController *popoverController;
@property (nonatomic, readonly, strong) UITableViewController *tableViewController;
@property (nonatomic, readonly, strong) UILabel *noResultsLabel;

- (IBAction) onChangePublishedFilterSegment: (id) sender;

@end

//
//  ExpandedTableView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExpandedTableViewDelegate.h"

@interface ExpandedTableView : UITableView<UITableViewDelegate, UITableViewDataSource> {
	id <UITableViewDelegate, ExpandedTableViewDelegate> expandedTableViewdDelegate;
	id <UITableViewDataSource> expandedTableViewdDataSource;
}
@property (nonatomic, assign) IBOutlet id <UITableViewDelegate, ExpandedTableViewDelegate> expandedTableViewdDelegate;
@property (nonatomic, assign) IBOutlet id <UITableViewDataSource> expandedTableViewdDataSource;

@end

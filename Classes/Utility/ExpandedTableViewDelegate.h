//
//  ExpandedTableViewDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExpandedTableView;
@protocol ExpandedTableViewDelegate <NSObject>

- (void) tableView:(UITableView*) tableView didExpandSection:(NSInteger) section;
- (void) tableView:(UITableView*) tableView didCollapseSection:(NSInteger) section;
- (BOOL) tableView:(UITableView*) tableView isExpandedSection:(NSInteger) section;

@end

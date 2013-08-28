//
//  MessagesViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterViewController.h"
#import "EUFilter.h"
#import "MessageGroupsDataSource.h"
#import "MessagesDataSource.h"

@class EUMailBox;
@interface MessagesViewController : UIViewController<MessageGroupsDataSourceDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet FilterViewController *filterViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *filterNavigationViewController;
@property (nonatomic, strong) UIPopoverController *filterPopoverController;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet MessageGroupsDataSource *messageGroupsDataSource;
@property (strong, nonatomic) IBOutlet MessagesDataSource *messagesDataSource;

@property (nonatomic, strong) NSArray* messages;

- (IBAction)markAsRead:(id)sender;

@end

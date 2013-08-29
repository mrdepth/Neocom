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
@interface MessagesViewController : UIViewController<MessageGroupsDataSourceDelegate, MessagesDataSourceDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableViewLeft;
@property (weak, nonatomic) IBOutlet UITableView *tableViewRight;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet MessageGroupsDataSource *messageGroupsDataSource;
@property (strong, nonatomic) IBOutlet MessagesDataSource *messagesDataSource;
@property (strong, nonatomic) IBOutlet MessagesDataSource *searchResultsDataSource;

@property (nonatomic, strong) NSArray* messages;
@property (nonatomic, strong) EUMailBox* mailBox;

- (IBAction)markAsRead:(id)sender;

@end

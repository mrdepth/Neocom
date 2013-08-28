//
//  MessagesDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 27.08.13.
//
//

#import <Foundation/Foundation.h>

@class EUMailMessage;
@class MessagesDataSource;
@protocol MessagesDataSourceDelegate
- (void) messageGroupsDataSource:(MessagesDataSource*) dataSource didSelectMessage:(EUMailMessage*) message;
@end

@interface MessagesDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet id<MessagesDataSourceDelegate> delegate;
@property (nonatomic, strong) NSArray* messages;
- (void) reload;

@end

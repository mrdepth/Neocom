//
//  MessageGroupsDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 25.08.13.
//
//

#import <Foundation/Foundation.h>

@class MessageGroupsDataSource;
@protocol MessageGroupsDataSourceDelegate
- (void) messageGroupsDataSource:(MessageGroupsDataSource*) dataSource didSelectGroup:(NSArray*) group withTitle:(NSString*) title;
@end

@interface MessageGroupsDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet id<MessageGroupsDataSourceDelegate> delegate;
- (void) reload;

@end

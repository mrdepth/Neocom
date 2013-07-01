//
//  KillNetFilterDBViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import <UIKit/UIKit.h>

@class KillNetFilterDBViewController;
@protocol KillNetFilterDBViewControllerDelegate
- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item;
@end


@interface KillNetFilterDBViewController : UITableViewController
@property (nonatomic, strong) NSString* groupsRequest;
@property (nonatomic, strong) NSString* itemsRequest;
@property (nonatomic, strong) NSString* searchRequest;
@property (nonatomic, assign) NSInteger groupID;
@property (nonatomic, strong) NSString* groupName;
@property (nonatomic, weak) id<KillNetFilterDBViewControllerDelegate> delegate;

@end

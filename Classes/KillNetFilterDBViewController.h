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
@property (nonatomic, retain) NSString* groupsRequest;
@property (nonatomic, retain) NSString* itemsRequest;
@property (nonatomic, retain) NSString* searchRequest;
@property (nonatomic, assign) NSInteger groupID;
@property (nonatomic, assign) NSString* groupName;
@property (nonatomic, assign) id<KillNetFilterDBViewControllerDelegate> delegate;

@end

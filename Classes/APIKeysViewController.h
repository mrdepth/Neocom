//
//  KeysViewController.h
//  EVEUniverse
//
//  Created by Shimanski on 9/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class APIKeysViewController;
@protocol APIKeysViewControllerDelegate<NSObject>
- (void) apiKeysViewController:(APIKeysViewController*) controller didSelectAPIKeys:(NSArray*) apiKeys;
@end


@interface APIKeysViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *keysTableView;
@property (nonatomic, strong) NSMutableArray *apiKeys;
@property (nonatomic, weak) id<APIKeysViewControllerDelegate> delegate;

@end

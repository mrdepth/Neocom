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
@property (nonatomic, retain) IBOutlet UITableView *keysTableView;
@property (nonatomic, retain) NSMutableArray *apiKeys;
@property (nonatomic, assign) id<APIKeysViewControllerDelegate> delegate;

@end

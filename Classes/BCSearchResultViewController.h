//
//  BCSearchResultViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface BCSearchResultViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
	UITableView *resultsTableView;
	EVEDBInvType *ship;
	NSArray *loadouts;
@private
	UIImage *shipImage;
}
@property (nonatomic, retain) IBOutlet UITableView *resultsTableView;
@property (nonatomic, retain) EVEDBInvType *ship;
@property (nonatomic, retain) NSArray *loadouts;


@end

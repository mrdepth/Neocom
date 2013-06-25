//
//  RSSFeedViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RSSFeedViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) IBOutlet UITableView *rssTableView;
@property (nonatomic, retain) IBOutlet UILabel *feedTitleLabel;
@property (nonatomic, retain) NSURL *url;
@end

//
//  RSSFeedViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RSSFeedViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *rssTableView;
@property (nonatomic, weak) IBOutlet UILabel *feedTitleLabel;
@property (nonatomic, strong) NSURL *url;
@end

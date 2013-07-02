//
//  BCSearchResultViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface BCSearchResultViewController : UITableViewController
@property (nonatomic, strong) EVEDBInvType *ship;
@property (nonatomic, strong) NSArray *loadouts;


@end

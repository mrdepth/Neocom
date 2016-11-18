//
//  NCAPIKeyInfoViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCAccount;
@interface NCAPIKeyInfoViewController : UITableViewController
@property (nonatomic, strong) NCAccount* account;
@end

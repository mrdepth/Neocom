//
//  NCDatabaseTypeInfoViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCDBInvType;
@interface NCDatabaseTypeInfoViewController : UITableViewController
@property (nonatomic, strong) NCDBInvType* type;

@end

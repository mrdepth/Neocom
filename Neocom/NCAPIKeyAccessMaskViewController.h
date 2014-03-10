//
//  NCAPIKeyAccessMaskViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCAccount;
@interface NCAPIKeyAccessMaskViewController : NCTableViewController
@property (nonatomic, strong) NCAccount* account;
@end

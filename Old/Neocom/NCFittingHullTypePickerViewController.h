//
//  NCFittingHullTypePickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 30.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBDgmppHullType;
@interface NCFittingHullTypePickerViewController : NCTableViewController
@property (nonatomic, strong) NCDBDgmppHullType* selectedHullType;
@end

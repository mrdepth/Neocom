//
//  NCFittingAPIFlagsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingAPIFlagsViewController : UITableViewController
@property (nonatomic, strong) NSArray* values;
@property (nonatomic, strong) NSArray* titles;
@property (nonatomic, strong) NSArray* icons;
@property (nonatomic, strong) NSNumber* selectedValue;

@end

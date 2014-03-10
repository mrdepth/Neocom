//
//  NCDatabaseTypeInfoViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 15.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class EVEDBInvType;
@interface NCDatabaseTypeInfoViewController : NCTableViewController
@property (nonatomic, strong) EVEDBInvType* type;

@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (weak, nonatomic) IBOutlet UILabel* descriptionLabel;
@end

//
//  NCTodayCell.h
//  Neocom
//
//  Created by Артем Шиманский on 28.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCTodayCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillQueueLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftMarginConstraint;

@end

//
//  NCTableViewCell.h
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCTableViewCell : UITableViewCell
@property (nonatomic, strong) id object;

@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView* iconView;


@property (nonatomic, weak) IBOutlet UIView* layoutContentView;

@end

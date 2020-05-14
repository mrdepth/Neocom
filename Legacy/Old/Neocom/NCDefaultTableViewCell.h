//
//  NCDefaultTableViewCell.h
//  Neocom
//
//  Created by Artem Shimanski on 12.02.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCDefaultTableViewCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView* iconView;

@end

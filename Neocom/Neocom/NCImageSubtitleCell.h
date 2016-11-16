//
//  NCImageSubtitleCell.h
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCImageSubtitleCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

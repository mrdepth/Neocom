//
//  NCShoppingItemCell.h
//  Neocom
//
//  Created by Artem Shimanski on 05.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCShoppingItemCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView* iconView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIView *anchorView;
@end

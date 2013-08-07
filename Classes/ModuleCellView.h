//
//  ModuleCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"

@interface ModuleCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UIImageView *stateView;
@property (nonatomic, weak) IBOutlet UIImageView *targetView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *row1Label;
@property (nonatomic, weak) IBOutlet UILabel *row2Label;
@property (nonatomic, weak) IBOutlet UILabel *row3Label;
@end

//
//  SkillCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"


@interface SkillCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *levelImageView;
@property (nonatomic, weak) IBOutlet UILabel *skillLabel;
@property (nonatomic, weak) IBOutlet UILabel *skillPointsLabel;
@property (nonatomic, weak) IBOutlet UILabel *levelLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainingLabel;

@end

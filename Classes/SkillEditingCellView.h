//
//  SkillEditingCellView.h
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SkillEditingCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *levelImageView;
@property (nonatomic, weak) IBOutlet UILabel *skillLabel;
@end

//
//  NCTableViewSkillCell.h
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCTableViewSkillCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (weak, nonatomic) IBOutlet UILabel *spLabel;
@property (weak, nonatomic) IBOutlet UILabel *trainingTimeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

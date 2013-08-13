//
//  DamagePatternCellView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GroupedCell.h"
#import "ProgressLabel.h"

@interface DamagePatternCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel* emLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel* kineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel* thermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel* explosiveLabel;


@end

//
//  DamagePatternCellView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLabel.h"

@interface DamagePatternCellView : UITableViewCell {
	UILabel* titleLabel;
	ProgressLabel* emLabel;
	ProgressLabel* kineticLabel;
	ProgressLabel* thermalLabel;
	ProgressLabel* explosiveLabel;
	UIImageView* checkmarkImageView;
}
@property (nonatomic, retain) IBOutlet UILabel* titleLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel* emLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel* kineticLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel* thermalLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel* explosiveLabel;
@property (nonatomic, retain) IBOutlet UIImageView* checkmarkImageView;


@end

//
//  SkillEditingCellView.h
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SkillEditingCellView : UITableViewCell {
	UIImageView *iconImageView;
	UIImageView *levelImageView;
	UILabel *skillLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UIImageView *levelImageView;
@property (nonatomic, retain) IBOutlet UILabel *skillLabel;
@end

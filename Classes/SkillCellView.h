//
//  SkillCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SkillCellView : UITableViewCell {
	UIImageView *iconImageView;
	UIImageView *levelImageView;
	UILabel *skillLabel;
	UILabel *skillPointsLabel;
	UILabel *levelLabel;
	UILabel *remainingLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UIImageView *levelImageView;
@property (nonatomic, retain) IBOutlet UILabel *skillLabel;
@property (nonatomic, retain) IBOutlet UILabel *skillPointsLabel;
@property (nonatomic, retain) IBOutlet UILabel *levelLabel;
@property (nonatomic, retain) IBOutlet UILabel *remainingLabel;

@end

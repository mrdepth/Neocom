//
//  IndustryJobCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IndustryJobCellView : UITableViewCell {
	UILabel *remainsLabel;
	UILabel *activityLabel;
	UILabel *typeNameLabel;
	UILabel *locationLabel;
	UILabel *startTimeLabel;
	UILabel *characterLabel;
	UIImageView *iconImageView;
	UIImageView *activityImageView;
}
@property (nonatomic, retain) IBOutlet UILabel *remainsLabel;
@property (nonatomic, retain) IBOutlet UILabel *activityLabel;
@property (nonatomic, retain) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *startTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *characterLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UIImageView *activityImageView;

@end

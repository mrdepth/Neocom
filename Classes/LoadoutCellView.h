//
//  LoadoutCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoadoutCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *thumbsUpLabel;
@property (nonatomic, retain) IBOutlet UILabel *thumbsDownLabel;

@end

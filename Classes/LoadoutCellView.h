//
//  LoadoutCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoadoutCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *thumbsUpLabel;
@property (nonatomic, weak) IBOutlet UILabel *thumbsDownLabel;

@end

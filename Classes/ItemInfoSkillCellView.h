//
//  ItemInfoSkillCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ItemInfoSkillCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UILabel *skillLabel;
@property (nonatomic, retain) IBOutlet UIView *hierarchyView;

@end

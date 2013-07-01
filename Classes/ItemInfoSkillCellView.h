//
//  ItemInfoSkillCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ItemInfoSkillCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconView;
@property (nonatomic, weak) IBOutlet UILabel *skillLabel;
@property (nonatomic, weak) IBOutlet UIView *hierarchyView;

@end

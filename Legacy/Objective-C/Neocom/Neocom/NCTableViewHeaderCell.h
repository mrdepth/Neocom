//
//  NCTableViewHeaderCell.h
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASTreeController.h"

@interface NCTableViewHeaderCell : UITableViewCell<ASExpandable>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *expandIcon;

@end

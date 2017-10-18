//
//  NCFittingBattleClinicSearchResultsCell.h
//  Neocom
//
//  Created by Артем Шиманский on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingBattleClinicSearchResultsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView* typeImageView;
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (weak, nonatomic) IBOutlet UILabel* thumbsUpCountLabel;
@property (weak, nonatomic) IBOutlet UILabel* thumbsDownCountLabel;
@property (strong, nonatomic) id object;
@end

//
//  NCFittingImplantsImportCell.h
//  Neocom
//
//  Created by Shimanski Artem on 08.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingImplantsImportCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (weak, nonatomic) IBOutlet UILabel* implantsLabel;
@property (nonatomic, strong) id object;

@end

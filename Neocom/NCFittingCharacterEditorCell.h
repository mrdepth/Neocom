//
//  NCFittingCharacterEditorCell.h
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingCharacterEditorCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *skillNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillLevelLabel;
@property (strong, nonatomic) id skillData;

@end

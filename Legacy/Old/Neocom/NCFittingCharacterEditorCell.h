//
//  NCFittingCharacterEditorCell.h
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingCharacterEditorCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *skillNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillLevelLabel;

@end

//
//  NCCharacterAttributesCell.h
//  Neocom
//
//  Created by Артем Шиманский on 13.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCCharacterAttributesCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *intelligenceLabel;
@property (weak, nonatomic) IBOutlet UILabel *memoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *perceptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *willpowerLabel;
@property (weak, nonatomic) IBOutlet UILabel *charismaLabel;

@end

//
//  NCAccountCharacterCell.h
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCAccountCharacterCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@end

//
//  NCKillMailDetailsAttackerCell.h
//  Neocom
//
//  Created by Артем Шиманский on 25.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCKillMailDetailsAttackerCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shipTypeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weaponTypeImageView;
@property (weak, nonatomic) IBOutlet UILabel *shipLabel;
@property (weak, nonatomic) IBOutlet UILabel *damageDoneLabel;
@property (strong, nonatomic) id object;
@end

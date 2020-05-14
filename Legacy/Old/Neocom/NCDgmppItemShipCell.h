//
//  NCDgmppItemShipCell.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCDgmppItemShipCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *typeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hiSlotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *medSlotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowSlotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *rigSlotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *turretsLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchersLabel;
@end

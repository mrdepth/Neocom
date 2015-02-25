//
//  NCFittingShipPriceCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingShipPriceCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *shipPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *fittingsPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalPriceLabel;

@end

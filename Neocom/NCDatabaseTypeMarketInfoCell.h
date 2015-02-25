//
//  NCDatabaseTypeMarketInfoCell.h
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCDatabaseTypeMarketInfoCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *solarSystemlabel;
@property (weak, nonatomic) IBOutlet UILabel *jumpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *stationLabel;

@end

//
//  NCFittingShipPriceCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingShipPriceCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *shipPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *fittingsPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalPriceLabel;

@end

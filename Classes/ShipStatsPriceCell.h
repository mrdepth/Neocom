//
//  ShipStatsPriceCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsPriceCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *shipPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *fittingsPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalPriceLabel;
@end

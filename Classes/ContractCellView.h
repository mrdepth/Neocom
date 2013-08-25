//
//  ContractCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupedCell.h"


@interface ContractCellView : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *startTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *characterLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *buyoutLabel;

@end

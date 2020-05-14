//
//  NCFittingShipCapacitorCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingShipCapacitorCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel *capacitorCapacityLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorRechargeTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorDeltaLabel;

@end

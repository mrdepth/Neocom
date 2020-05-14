//
//  NCFittingDamageVectorCell.h
//  Neocom
//
//  Created by Artem Shimanski on 06.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCFittingDamageVectorCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet NCProgressLabel *emLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *thermalLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *kineticLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *explosiveLabel;

@end

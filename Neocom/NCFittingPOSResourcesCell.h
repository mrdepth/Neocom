//
//  NCFittingPOSResourcesCell.h
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCFittingPOSResourcesCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet NCProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *cpuLabel;
@end

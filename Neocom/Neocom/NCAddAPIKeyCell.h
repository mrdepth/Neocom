//
//  NCAddAPIKeyCell.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDefaultTableViewCell.h"

@interface NCAddAPIKeyCell : NCDefaultTableViewCell
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;
@property (strong, nonatomic) id object;

@end

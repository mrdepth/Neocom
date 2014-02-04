//
//  NCFittingDamagePatternEditorViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCProgressTextField.h"
#import "NCProgressLabel.h"

@class NCDamagePattern;
@interface NCFittingDamagePatternEditorViewController : UITableViewController
@property (weak, nonatomic) IBOutlet NCProgressTextField *emTextField;
@property (weak, nonatomic) IBOutlet NCProgressTextField *thermalTextField;
@property (weak, nonatomic) IBOutlet NCProgressTextField *kineticTextField;
@property (weak, nonatomic) IBOutlet NCProgressTextField *explosiveTextField;
@property (weak, nonatomic) IBOutlet NCProgressLabel *totalLabel;
@property (strong, nonatomic) NCDamagePattern* damagePattern;

@end

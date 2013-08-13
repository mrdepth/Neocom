//
//  DamagePatternEditViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressTextField.h"
#import "ProgressLabel.h"
#import "GroupedCell.h"

@class DamagePattern;
@interface DamagePatternEditViewController : UITableViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet GroupedCell *damageAmountsCellView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *emTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *thermalTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *kineticTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *explosiveTextField;
@property (weak, nonatomic) IBOutlet ProgressLabel *totalDamageLabel;
@property (strong, nonatomic) DamagePattern* damagePattern;

- (IBAction)onSave:(id)sender;

@end

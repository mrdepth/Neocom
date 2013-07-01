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

@class DamagePattern;
@interface DamagePatternEditViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *damageAmountsCellView;
@property (strong, nonatomic) IBOutlet UITableViewCell *titleCellView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *emTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *thermalTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *kineticTextField;
@property (weak, nonatomic) IBOutlet ProgressTextField *explosiveTextField;
@property (weak, nonatomic) IBOutlet ProgressLabel *totalDamageLabel;
@property (strong, nonatomic) DamagePattern* damagePattern;

- (IBAction)onSave:(id)sender;

@end

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
@interface DamagePatternEditViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	UITableView* tableView;
	UITableViewCell *damageAmountsCellView;
	UITableViewCell *titleCellView;
	UITextField *titleTextField;
	ProgressTextField *emTextField;
	ProgressTextField *thermalTextField;
	ProgressTextField *kineticTextField;
	ProgressTextField *explosiveTextField;
	ProgressLabel *totalDamageLabel;
	DamagePattern* damagePattern;
}
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UITableViewCell *damageAmountsCellView;
@property (retain, nonatomic) IBOutlet UITableViewCell *titleCellView;
@property (retain, nonatomic) IBOutlet UITextField *titleTextField;
@property (retain, nonatomic) IBOutlet ProgressTextField *emTextField;
@property (retain, nonatomic) IBOutlet ProgressTextField *thermalTextField;
@property (retain, nonatomic) IBOutlet ProgressTextField *kineticTextField;
@property (retain, nonatomic) IBOutlet ProgressTextField *explosiveTextField;
@property (retain, nonatomic) IBOutlet ProgressLabel *totalDamageLabel;
@property (retain, nonatomic) DamagePattern* damagePattern;

- (IBAction)onSave:(id)sender;

@end

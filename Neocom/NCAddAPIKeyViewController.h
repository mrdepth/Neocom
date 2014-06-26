//
//  NCAddAPIKeyViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 18.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCAddAPIKeyViewController : NCTableViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UITextField *keyIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *vCodeTextField;
- (IBAction)onSave:(id)sender;

@end

//
//  AddEVEAccountViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"

@interface AddEVEAccountViewController : UIViewController<UITextFieldDelegate, BrowserViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UITextField *keyIDTextField;
@property (nonatomic, weak) IBOutlet UITextField *vCodeTextField;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *saveButton;

- (IBAction) onBrowser: (id) sender;
- (IBAction) onSafari: (id) sender;
- (IBAction) onPC: (id) sender;
- (IBAction) onSave: (id) sender;
- (IBAction) onToutorial: (id) sender;
@end

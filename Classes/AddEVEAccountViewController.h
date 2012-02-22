//
//  AddEVEAccountViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"
#import "APIKeysViewController.h"

@interface AddEVEAccountViewController : UIViewController<UITextFieldDelegate, BrowserViewControllerDelegate, UIAlertViewDelegate, APIKeysViewControllerDelegate> {
	UITextField *keyIDTextField;
	UITextField *vCodeTextField;
	UIBarButtonItem *saveButton;
}
@property (nonatomic, retain) IBOutlet UITextField *keyIDTextField;
@property (nonatomic, retain) IBOutlet UITextField *vCodeTextField;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *saveButton;

- (IBAction) onBrowser: (id) sender;
- (IBAction) onSafari: (id) sender;
- (IBAction) onPC: (id) sender;
- (IBAction) onSave: (id) sender;
- (IBAction) onToutorial: (id) sender;
@end

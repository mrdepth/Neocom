//
//  DronesAmountViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DronesAmountViewControllerDelegate.h"


@interface DronesAmountViewController : UIViewController<UIPickerViewDataSource, UIPopoverControllerDelegate>
@property (nonatomic, retain) IBOutlet UIPickerView *pickerView;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, assign) NSInteger maxAmount;
@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, assign) id<DronesAmountViewControllerDelegate> delegate;

- (void) presentAnimated:(BOOL) animated;
- (void) dismissAnimated:(BOOL) animated;
- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

- (IBAction) onCancel:(id) sender;
- (IBAction) onDone:(id) sender;

@end

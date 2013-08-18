//
//  KillNetFilterDateViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import <UIKit/UIKit.h>
#import "GroupedCell.h"

@class KillNetFilterDateViewController;
@protocol KillNetFilterDateViewControllerDelegate
- (void) killNetFilterDateViewController:(KillNetFilterDateViewController*) controller didSelectDate:(NSDate*) date;
@end

@interface KillNetFilterDateViewController : UIViewController
@property (weak, nonatomic) IBOutlet GroupedCell* cell;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) NSDate* minimumDate;
@property (strong, nonatomic) NSDate* maximumDate;
@property (strong, nonatomic) NSDate* date;
@property (weak, nonatomic) id<KillNetFilterDateViewControllerDelegate> delegate;
- (IBAction)onChangeDate:(id)sender;

@end

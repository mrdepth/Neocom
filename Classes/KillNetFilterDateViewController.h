//
//  KillNetFilterDateViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 14.11.12.
//
//

#import <UIKit/UIKit.h>

@class KillNetFilterDateViewController;
@protocol KillNetFilterDateViewControllerDelegate
- (void) killNetFilterDateViewController:(KillNetFilterDateViewController*) controller didSelectDate:(NSDate*) date;
@end

@interface KillNetFilterDateViewController : UIViewController
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *valueLabel;
@property (retain, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (retain, nonatomic) NSDate* minimumDate;
@property (retain, nonatomic) NSDate* maximumDate;
@property (retain, nonatomic) NSDate* date;
@property (assign, nonatomic) id<KillNetFilterDateViewControllerDelegate> delegate;
- (IBAction)onChangeDate:(id)sender;

@end

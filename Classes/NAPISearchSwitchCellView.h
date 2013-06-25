//
//  NAPISearchSwitchCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import <UIKit/UIKit.h>

@class NAPISearchSwitchCellView;
@protocol NAPISearchSwitchCellViewDelegate<NSObject>

- (void) switchCellViewDidSwitch:(NAPISearchSwitchCellView*) cellView;

@end

@interface NAPISearchSwitchCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;
@property (weak, nonatomic) id<NAPISearchSwitchCellViewDelegate> delegate;
- (IBAction)onSwitch:(id)sender;

@end

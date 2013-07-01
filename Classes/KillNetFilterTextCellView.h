//
//  KillNetFilterTextCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import <UIKit/UIKit.h>

@class KillNetFilterTextCellView;
@protocol KillNetFilterTextCellViewDelegate <NSObject>
- (void) killNetFilterTextCellViewDidPressDefaultButton:(KillNetFilterTextCellView*) cell;
@end

@interface KillNetFilterTextCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, weak) id<KillNetFilterTextCellViewDelegate> delegate;

- (IBAction)onDefaultValue:(id)sender;

@end

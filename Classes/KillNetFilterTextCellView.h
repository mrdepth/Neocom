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
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, assign) id<KillNetFilterTextCellViewDelegate> delegate;

- (IBAction)onDefaultValue:(id)sender;

@end

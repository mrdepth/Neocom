//
//  KillNetFilterTextCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "GroupedCell.h"
#import "ASCaptionTextField.h"

@class KillNetFilterTextCellView;
@protocol KillNetFilterTextCellViewDelegate <NSObject>
- (void) killNetFilterTextCellViewDidPressDefaultButton:(KillNetFilterTextCellView*) cell;
@end

@interface KillNetFilterTextCellView : GroupedCell
@property (weak, nonatomic) IBOutlet ASCaptionTextField* textField;
@property (nonatomic, weak) id<KillNetFilterTextCellViewDelegate> delegate;


- (IBAction)onDefaultValue:(id)sender;

@end

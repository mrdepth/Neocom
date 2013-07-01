//
//  AccountsSelectionCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import <UIKit/UIKit.h>

@interface AccountsSelectionCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corpImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corpNameLabel;

@end

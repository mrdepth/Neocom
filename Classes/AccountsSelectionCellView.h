//
//  AccountsSelectionCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import <UIKit/UIKit.h>

@interface AccountsSelectionCellView : UITableViewCell
@property (retain, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (retain, nonatomic) IBOutlet UIImageView *corpImageView;
@property (retain, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *corpNameLabel;

@end

//
//  EVEAccountCell.h
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import <UIKit/UIKit.h>

@class EVEAccountCell;
@protocol EVEAccountCellDelegate<NSObject>
- (void) accountCell:(EVEAccountCell*) cell deleteButtonTapped:(UIButton*) button;
- (void) accountCell:(EVEAccountCell*) cell favoritesButtonTapped:(UIButton*) button;
- (void) accountCell:(EVEAccountCell*) cell charKeyButtonTapped:(UIButton*) button;
- (void) accountCell:(EVEAccountCell*) cell corpKeyButtonTapped:(UIButton*) button;
@end

@class EVEAccount;
@interface EVEAccountCell : UICollectionViewCell
@property (nonatomic, weak) IBOutlet UIImageView *portraitImageView;
@property (nonatomic, weak) IBOutlet UIImageView *corpImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corpLabel;
@property (weak, nonatomic) IBOutlet UILabel *wealthLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillsLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipLabel;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *charKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *corpKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (nonatomic, strong) EVEAccount* account;
@property (nonatomic, assign) BOOL editing;
@property (weak, nonatomic) id<EVEAccountCellDelegate> delegate;

- (IBAction)onDelete:(id)sender;
- (IBAction)onFavorite:(id)sender;
- (IBAction)onCharKey:(id)sender;
- (IBAction)onCorpKey:(id)sender;
- (void) setEditing:(BOOL)editing animated:(BOOL)animated;
@end

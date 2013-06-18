//
//  NAPISearchTitleCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import <UIKit/UIKit.h>

@class NAPISearchTitleCellView;
@protocol NAPISearchTitleCellViewDelegate<NSObject>

- (void) searchTitleCellViewDidClear:(NAPISearchTitleCellView*) cellView;

@end

@interface NAPISearchTitleCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) id<NAPISearchTitleCellViewDelegate> delegate;
- (IBAction)onClear:(id)sender;

@end

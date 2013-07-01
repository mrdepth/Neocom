//
//  KillMailItemCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillMailItemCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *qualityLabel;
@property (nonatomic, assign) BOOL destroyed;

@end

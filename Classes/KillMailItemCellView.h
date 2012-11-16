//
//  KillMailItemCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillMailItemCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UIImageView *iconImageView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *qualityLabel;
@property (nonatomic, assign) BOOL destroyed;

@end

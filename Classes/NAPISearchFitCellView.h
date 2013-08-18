//
//  NAPISearchFitCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 19.06.13.
//
//

#import "GroupedCell.h"

@interface NAPISearchFitCellView : GroupedCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *ehpLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tankTypeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weaponTypeImageView;
@property (weak, nonatomic) IBOutlet UILabel *turretDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *falloffLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *capacitorLabel;

@end

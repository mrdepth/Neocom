//
//  ShipStatsMiscCell.h
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "GroupedCell.h"

@interface ShipStatsMiscCell : GroupedCell
@property (nonatomic, weak) IBOutlet UILabel *targetsLabel;
@property (nonatomic, weak) IBOutlet UILabel *targetRangeLabel;
@property (nonatomic, weak) IBOutlet UILabel *scanResLabel;
@property (nonatomic, weak) IBOutlet UILabel *sensorStrLabel;
@property (nonatomic, weak) IBOutlet UILabel *speedLabel;
@property (nonatomic, weak) IBOutlet UILabel *alignTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *signatureLabel;
@property (nonatomic, weak) IBOutlet UILabel *cargoLabel;
@property (nonatomic, weak) IBOutlet UIImageView *sensorImageView;
@property (nonatomic, weak) IBOutlet UILabel *droneRangeLabel;
@property (nonatomic, weak) IBOutlet UILabel *warpSpeedLabel;

@end

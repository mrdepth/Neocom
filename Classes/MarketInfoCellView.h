//
//  MarketInfoCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MarketInfoCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *systemLabel;
@property (nonatomic, weak) IBOutlet UILabel *stationLabel;
@property (nonatomic, weak) IBOutlet UILabel *securityLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;
@property (nonatomic, weak) IBOutlet UILabel *qtyLabel;
@property (nonatomic, weak) IBOutlet UILabel *reportedLabel;

@end

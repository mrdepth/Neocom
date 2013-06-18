//
//  MarketInfoCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MarketInfoCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel *systemLabel;
@property (nonatomic, retain) IBOutlet UILabel *stationLabel;
@property (nonatomic, retain) IBOutlet UILabel *securityLabel;
@property (nonatomic, retain) IBOutlet UILabel *priceLabel;
@property (nonatomic, retain) IBOutlet UILabel *qtyLabel;
@property (nonatomic, retain) IBOutlet UILabel *reportedLabel;

@end

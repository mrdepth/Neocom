//
//  ContractInfoCellView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ContractInfoCellView : UITableViewCell {
	UILabel *titleLabel;
	UILabel *valueLabel;
}
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *valueLabel;

@end

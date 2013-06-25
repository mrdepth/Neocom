//
//  APIKeysKeyCellView.h
//  EVEUniverse
//
//  Created by Shimanski on 9/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface APIKeysKeyCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UILabel *keyIDLabel;
@property (nonatomic, retain) IBOutlet UILabel *vCodeLabel;
@property (nonatomic, retain) IBOutlet UIImageView *checkmarkImageView;

@end

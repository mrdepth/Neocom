//
//  APIKeysKeyCellView.h
//  EVEUniverse
//
//  Created by Shimanski on 9/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface APIKeysKeyCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *keyIDLabel;
@property (nonatomic, weak) IBOutlet UILabel *vCodeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *checkmarkImageView;

@end

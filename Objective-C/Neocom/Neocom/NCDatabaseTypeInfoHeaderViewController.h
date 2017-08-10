//
//  NCDatabaseTypeInfoHeaderViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCDBInvType;
@interface NCDatabaseTypeInfoHeaderViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NCDBInvType* type;

@end

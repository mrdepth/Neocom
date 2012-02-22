//
//  CertificateView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CertificateView : UIView {
	UIImageView *iconView;
	UIImageView *statusView;
	UILabel *titleLabel;
	UILabel *descriptionLabel;
	UIColor* color;
}
@property (retain, nonatomic) IBOutlet UIImageView *iconView;
@property (retain, nonatomic) IBOutlet UIImageView *statusView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (retain, nonatomic) UIColor* color;

@end


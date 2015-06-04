//
//  NCBannerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCBannerView : UIView

@end

@interface NCBannerViewController : UINavigationController
@property (nonatomic, strong) IBOutlet NCBannerView* bannerView;
@end

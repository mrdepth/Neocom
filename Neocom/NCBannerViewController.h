//
//  NCBannerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCNavigationController.h"


@interface NCBannerView : UIView

@end

@interface NCBannerViewController : NCNavigationController
@property (nonatomic, strong) IBOutlet NCBannerView* bannerView;
@end

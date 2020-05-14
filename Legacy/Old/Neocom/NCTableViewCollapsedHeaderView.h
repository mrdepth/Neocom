//
//  NCTableViewCollapsedHeaderView.h
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewHeaderView.h"

@interface NCTableViewCollapsedHeaderView : NCTableViewHeaderView
@property (nonatomic, assign) BOOL collapsed;
@property (nonatomic, weak) IBOutlet UIImageView* imageView;

@end

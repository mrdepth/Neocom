//
//  NCTableViewCell.h
//  Neocom
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASBinder.h"

@interface NCTableViewCell : UITableViewCell
@property (nonatomic, strong) id object;
@property (nonatomic, strong, readonly) ASBinder* binder;
@end

//
//  NCTableViewLazyDataSource.h
//  Neocom
//
//  Created by Артем Шиманский on 17.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCTableViewLazyDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak) id<UITableViewDelegate> delegate;

@end

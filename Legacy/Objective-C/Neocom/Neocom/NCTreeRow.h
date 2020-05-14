//
//  NCTreeRow.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTreeNode.h"

@interface NCTreeRow : NCTreeNode

+ (instancetype) rowWithCellIdentifier:(NSString*) cellIdentifier configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block;
- (instancetype) initWithCellIdentifier:(NSString*) cellIdentifier configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block;


@end

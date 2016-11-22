//
//  NCTreeNode.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCTreeNode : NSObject
@property (nonatomic, readonly) NSArray<NCTreeNode*>* children;
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, strong) NSString* nodeIdentifier;
@property (nonatomic, readonly) BOOL canExpand;
@property (nonatomic, assign) BOOL expanded;

- (id) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier;
- (void) configure:(__kindof UITableViewCell*) tableViewCell;

@end

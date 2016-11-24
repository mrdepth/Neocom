//
//  NCTreeSection.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTreeNode.h"

@interface NCTreeSection : NCTreeNode
@property (nonatomic, strong, readwrite) NSArray<NCTreeNode*>* children;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSAttributedString* attributedTitle;

+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier children:(NSArray<NCTreeNode*>*) children configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block;
+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier title:(NSString*) title children:(NSArray<NCTreeNode*>*) children;
+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier attributedTitle:(NSAttributedString*) attributedTitle children:(NSArray<NCTreeNode*>*) children;
- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier children:(NSArray<NCTreeNode*>*) children configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block;
- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier title:(NSString*) title children:(NSArray<NCTreeNode*>*) children;
- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier attributedTitle:(NSAttributedString*) attributedTitle children:(NSArray<NCTreeNode*>*) children;
@end

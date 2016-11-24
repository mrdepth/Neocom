//
//  NCTreeSection.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTreeSection.h"
#import "NCTableViewHeaderCell.h"

@interface NCTreeSection()
@property (nonatomic, copy) void(^configurationHandler)(__kindof UITableViewCell* tableViewCell);
@end

@implementation NCTreeSection
@synthesize children = _children;

+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier children:(NSArray<NCTreeNode*>*) children configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block {
	return [[self alloc] initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier children:children configurationHandler:block];
}

+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier title:(NSString*) title children:(NSArray<NCTreeNode*>*) children {
	return [[self alloc] initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier title:title children:children];
}

+ (instancetype) sectionWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier attributedTitle:(NSAttributedString*) attributedTitle children:(NSArray<NCTreeNode*>*) children {
	return [[self alloc] initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier attributedTitle:attributedTitle children:children];
}

- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier children:(NSArray<NCTreeNode*>*) children configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block {
	if (self = [super initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier]) {
		self.configurationHandler = block;
		self.children = children;
	}
	return self;
}

- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier title:(NSString*) title children:(NSArray<NCTreeNode*>*) children {
	if (self = [super initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier]) {
		self.title = title;
		self.children = children;
	}
	return self;
}

- (instancetype) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier attributedTitle:(NSAttributedString*) attributedTitle children:(NSArray<NCTreeNode*>*) children {
	if (self = [super initWithNodeIdentifier:nodeIdentifier cellIdentifier:cellIdentifier]) {
		self.attributedTitle = attributedTitle;
		self.children = children;
	}
	return self;
}

- (void) configure:(__kindof UITableViewCell *)tableViewCell {
	if (self.configurationHandler)
		self.configurationHandler(tableViewCell);
	else {
		NCTableViewHeaderCell* cell = (NCTableViewHeaderCell*) tableViewCell;
		if (self.attributedTitle)
			cell.titleLabel.attributedText = self.attributedTitle;
		else
			cell.titleLabel.text = self.title;
	}
}

- (BOOL) canExpand {
	return YES;
}

@end

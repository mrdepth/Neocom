//
//  NCTreeNode.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTreeNode.h"

@implementation NCTreeNode

- (id) initWithNodeIdentifier:(NSString*) nodeIdentifier cellIdentifier:(NSString*) cellIdentifier {
	if (self = [super init]) {
		self.nodeIdentifier = nodeIdentifier;
		self.cellIdentifier = cellIdentifier;
	}
	return self;
}

- (void) configure:(__kindof UITableViewCell*) tableViewCell {
	
}

- (BOOL) canExpand {
	return self.children.count > 0;
}

- (NSArray<NCTreeNode*>*) children {
	return nil;
}


@end

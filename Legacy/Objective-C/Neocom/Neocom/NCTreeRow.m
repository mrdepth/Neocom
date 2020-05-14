//
//  NCTreeRow.m
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTreeRow.h"

@interface NCTreeRow()
@property (nonatomic, copy) void(^configurationHandler)(__kindof UITableViewCell* tableViewCell);
@end

@implementation NCTreeRow

+ (instancetype) rowWithCellIdentifier:(NSString*) cellIdentifier configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block {
	return [[self alloc] initWithCellIdentifier:cellIdentifier configurationHandler:block];
}

- (instancetype) initWithCellIdentifier:(NSString*) cellIdentifier configurationHandler:(void(^)(__kindof UITableViewCell* cell)) block {
		if (self = [super initWithNodeIdentifier:nil cellIdentifier:cellIdentifier]) {
			self.configurationHandler = block;
		}
		return self;
	}

- (void) configure:(__kindof UITableViewCell *)tableViewCell {
	if (self.configurationHandler)
		self.configurationHandler(tableViewCell);
}

@end

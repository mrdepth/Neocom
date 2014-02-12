//
//  NCFittingPOSAssemblyLinesDataSource.m
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSAssemblyLinesDataSource.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NSArray+Neocom.h"

@interface NCFittingPOSAssemblyLinesDataSourceRow : NSObject
@property (nonatomic, strong) EVEDBRamAssemblyLineType* assemblyLineType;
@property (nonatomic, assign) NSInteger count;
@end

@implementation NCFittingPOSAssemblyLinesDataSourceRow

@end

@interface NCFittingPOSAssemblyLinesDataSource()
@property (nonatomic, strong) NSArray* sections;
//@property (nonatomic, strong, readwrite) NCFittingShipDronesTableHeaderView* tableHeaderView;
@end

@implementation NCFittingPOSAssemblyLinesDataSource

- (void) reload {
	self.sections = nil;
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
	
	__block NSArray* sections = nil;
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
															
															NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary new];
															
															float n = controlTower->getStructures().size();
															float j = 0;
															for (auto structure: controlTower->getStructures()) {
																task.progress = j++ / n;
																if (structure->getState() >= eufe::Module::STATE_ACTIVE) {
																	EVEDBInvType* type = [self.controller typeWithItem:structure];
																	if (type) {
																		for (EVEDBRamInstallationTypeContent* installation in type.installations) {
																			NCFittingPOSAssemblyLinesDataSourceRow* row = assemblyLinesTypes[@(installation.assemblyLineTypeID)];
																			if (!row) {
																				row = [NCFittingPOSAssemblyLinesDataSourceRow new];
																				row.assemblyLineType = installation.assemblyLineType;
																				row.count = 1;
																				assemblyLinesTypes[@(installation.assemblyLineTypeID)] = row;
																			}
																			else
																				row.count++;
																		}
																	}
																}
															}
															sections = [[assemblyLinesTypes allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assemblyLineType.assemblyLineTypeName" ascending:YES]]];
															sections = [sections arrayGroupedByKey:@"assemblyLineType.activityID"];
															sections = [sections sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
																NCFittingPOSAssemblyLinesDataSourceRow* a = [obj1 objectAtIndex:0];
																NCFittingPOSAssemblyLinesDataSourceRow* b = [obj2 objectAtIndex:0];
																return [a.assemblyLineType.activity.activityName compare:b.assemblyLineType.activity.activityName];
															}];
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.sections = sections;
												
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
											}
										}];
}


/*- (NCFittingShipDronesTableHeaderView*) tableHeaderView {
 if (!_tableHeaderView) {
 _tableHeaderView = [NCFittingShipDronesTableHeaderView viewWithNibName:@"NCFittingShipDronesTableHeaderView" bundle:nil];
 }
 return _tableHeaderView;
 }*/

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.sections[section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingPOSAssemblyLinesDataSourceRow* row = self.sections[indexPath.section][indexPath.row];
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.assemblyLineType.assemblyLineTypeName, row.count];
	cell.imageView.image = [UIImage imageNamed:row.assemblyLineType.activity.iconImageName];
	cell.detailTextLabel.text = nil;
	cell.accessoryView = nil;
	
	return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NCFittingPOSAssemblyLinesDataSourceRow* row = self.sections[section][0];
	return row.assemblyLineType.activity.activityName;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

@end

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
#import "NCTableViewHeaderView.h"

@interface NCFittingPOSAssemblyLinesDataSourceRow : NSObject
@property (nonatomic, strong) NCDBRamAssemblyLineType* assemblyLineType;
@property (nonatomic, assign) NSInteger count;
@end

@implementation NCFittingPOSAssemblyLinesDataSourceRow

@end

@interface NCFittingPOSAssemblyLinesDataSource()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NCTableViewCell* offscreenCell;

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath;
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
														//@synchronized(self.controller) {
															eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
															
															NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary new];
															
															float n = controlTower->getStructures().size();
															float j = 0;
															for (auto structure: controlTower->getStructures()) {
																task.progress = j++ / n;
																if (structure->getState() >= eufe::Module::STATE_ACTIVE) {
																	NCDBInvType* type = [self.controller typeWithItem:structure];
																	if (type) {
																		for (NCDBRamInstallationTypeContent* installation in type.installationTypeContents) {
																			NCFittingPOSAssemblyLinesDataSourceRow* row = assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)];
																			if (!row) {
																				row = [NCFittingPOSAssemblyLinesDataSourceRow new];
																				row.assemblyLineType = installation.assemblyLineType;
																				row.count = 1;
																				assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)] = row;
																			}
																			else
																				row.count++;
																		}
																	}
																}
															}
															sections = [[assemblyLinesTypes allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assemblyLineType.assemblyLineTypeName" ascending:YES]]];
															sections = [sections arrayGroupedByKey:@"assemblyLineType.activity.activityID"];
															sections = [sections sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
																NCFittingPOSAssemblyLinesDataSourceRow* a = [obj1 objectAtIndex:0];
																NCFittingPOSAssemblyLinesDataSourceRow* b = [obj2 objectAtIndex:0];
																return [a.assemblyLineType.activity.activityName compare:b.assemblyLineType.activity.activityName];
															}];
														//}
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
    return [(NSArray*) self.sections[section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
	return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NCFittingPOSAssemblyLinesDataSourceRow* row = self.sections[section][0];
	return row.assemblyLineType.activity.activityName;
}

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		view.textLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	return title ? 44 : 0;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
		return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
		return UITableViewAutomaticDimension;

	if (!self.offscreenCell)
		self.offscreenCell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self tableView:tableView configureCell:self.offscreenCell forRowAtIndexPath:indexPath];
	self.offscreenCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.offscreenCell.bounds));
	[self.offscreenCell layoutIfNeeded];
	return [self.offscreenCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void) tableView:(UITableView *)tableView configureCell:(NCTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingPOSAssemblyLinesDataSourceRow* row = self.sections[indexPath.section][indexPath.row];
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.assemblyLineType.assemblyLineTypeName, (int32_t) row.count];
	cell.iconView.image = row.assemblyLineType.activity.icon ? row.assemblyLineType.activity.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.subtitleLabel.text = nil;
	cell.accessoryView = nil;
}

@end

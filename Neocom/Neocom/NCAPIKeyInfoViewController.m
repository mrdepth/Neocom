//
//  NCAPIKeyInfoViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAPIKeyInfoViewController.h"
#import "NCStorage.h"
#import "NCSwitchTitleCell.h"
#import "NCProgressHandler.h"
#import "NCDataManager.h"
#import "NCTableViewBackgroundLabel.h"

@interface NCAPIKeyInfoViewController()
@property (nonatomic, strong) EVECallList* callList;
@property (nonatomic, strong) NSArray<NSDictionary<NSString*, id>*>* sections;
@property (nonatomic, assign) int32_t accessMask;

@end

@implementation NCAPIKeyInfoViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.accessMask = self.account.apiKey.apiKeyInfo.key.accessMask;
	self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"KeyID %d", nil), (int) self.account.apiKey.keyID];
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	self.tableView.backgroundView = [NCTableViewBackgroundLabel labelWithText:NSLocalizedString(@"LOADING", nil)];
	[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"rows"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCSwitchTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	EVECallListCallsItem* call = self.sections[indexPath.section][@"rows"][indexPath.row];
	cell.titleLabel.text = call.name;
	cell.switchView.on = (self.accessMask & call.accessMask) == call.accessMask;
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:1];
	NCDataManager* dataManager = [NCDataManager defaultManager];
	[dataManager callListWithCachePolicy:cachePolicy completionHandler:^(EVECallList *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		[progressHandler finish];
		self.callList = result;
		
		NSMutableDictionary* groups = [NSMutableDictionary new];
		for (EVECallListCallGroupsItem* group in result.callGroups)
			groups[@(group.groupID)] = @{@"title":group.name ?: @"", @"rows":[NSMutableArray new]};
		
		NSArray* calls = [result.calls filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %d", self.account.eveAPIKey.corporate ? EVECallTypeCorporation : EVECallTypeCharacter]];
		
		for (EVECallListCallGroupsItem* item in [calls sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]])
			[groups[@(item.groupID)][@"rows"] addObject:item];
		self.sections = [[[groups allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"rows.@count > 0"]]sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
		
		[self.refreshControl endRefreshing];
		
		if (error &&!self.sections)
			self.tableView.backgroundView = [NCTableViewBackgroundLabel labelWithText:[error localizedDescription]];
		else
			self.tableView.backgroundView = nil;
			
		[self.tableView reloadData];
	}];
}

- (IBAction)onRefresh:(id)sender {
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

@end

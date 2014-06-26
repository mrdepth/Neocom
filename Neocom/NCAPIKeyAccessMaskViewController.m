//
//  NCAPIKeyAccessMaskViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAPIKeyAccessMaskViewController.h"
#import "NSArray+Neocom.h"

@interface NCAPIKeyAccessMaskViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* groups;
@end

@implementation NCAPIKeyAccessMaskViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.groups[@([self.sections[section][0] groupID])];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	EVECalllistCallsItem *call = self.sections[indexPath.section][indexPath.row];
	cell.textLabel.text = call.name;
	
	UIImage* accessoryImage = nil;
	if (self.account.apiKey.apiKeyInfo.key.accessMask & call.accessMask)
		accessoryImage = [UIImage imageNamed:@"checkmark.png"];
	cell.accessoryView = accessoryImage ? [[UIImageView alloc] initWithImage:accessoryImage] : nil;
    return cell;
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return @"EVECalllist";
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	
	__block EVECalllist* calllist = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 calllist = [EVECalllist calllistWithCachePolicy:NSURLRequestUseProtocolCachePolicy error:&error progressHandler:nil];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 [self didFinishLoadData:calllist withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3600 * 24 * 7]];
								 }
							 }];
}

- (void) update {
	EVECalllist* calllist = self.data;
	NSMutableDictionary* groups = [NSMutableDictionary new];
	for (EVECalllistCallGroupsItem *callGroup in calllist.callGroups) {
		groups[@(callGroup.groupID)] = callGroup.name;
	}
	self.groups = groups;
	
	BOOL corporate = self.account.accountType == NCAccountTypeCorporate;
	
	NSIndexSet *indexes = [calllist.calls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return corporate ^ ([(EVECalllistCallsItem*) obj type] == EVECallTypeCharacter);
	}];
	
	NSArray* sections;
	sections = [[calllist.calls objectsAtIndexes:indexes] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	sections = [sections arrayGroupedByKey:@"groupID"];
	sections = [sections sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSInteger groupID1 = [[obj1 objectAtIndex:0] groupID];
		NSInteger groupID2 = [[obj2 objectAtIndex:0] groupID];
		NSString *name1 = groups[@(groupID1)];
		NSString *name2 = groups[@(groupID2)];
		return [name1 compare:name2];
	}];
	self.sections = sections;
	[super update];
}


@end

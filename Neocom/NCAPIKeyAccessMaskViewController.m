//
//  NCAPIKeyAccessMaskViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAPIKeyAccessMaskViewController.h"
#import "NSArray+Neocom.h"
#import <EVEAPI/EVEAPI.h>

@interface NCAPIKeyAccessMaskViewController ()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NSDictionary* groups;
@property (nonatomic, assign) int32_t accessMask;
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
	self.cacheRecordID = @"EVECalllist";
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
	EVECallListCallsItem *call = self.sections[indexPath.section][indexPath.row];
	cell.textLabel.text = call.name;
	
	UIImage* accessoryImage = nil;
	if (self.accessMask & call.accessMask)
		accessoryImage = [UIImage imageNamed:@"checkmark"];
	cell.accessoryView = accessoryImage ? [[UIImageView alloc] initWithImage:accessoryImage] : nil;
    return cell;
}


#pragma mark - NCTableViewController

- (NSString*) recordID {
	return @"EVECalllist";
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	[[EVEOnlineAPI new] callListWithCompletionBlock:^(EVECallList *result, NSError *error) {
		[self saveCacheData:result cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:3600 * 24 * 7]];
		completionBlock(nil);
	} progressBlock:nil];
}

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	[self.account.managedObjectContext performBlock:^{
		EVECallList* calllist = cacheData;
		NSMutableDictionary* groups = [NSMutableDictionary new];
		for (EVECallListCallGroupsItem *callGroup in calllist.callGroups) {
			groups[@(callGroup.groupID)] = callGroup.name;
		}
		self.groups = groups;
		
		BOOL corporate = self.account.accountType == NCAccountTypeCorporate;
		
		NSIndexSet *indexes = [calllist.calls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			return corporate ^ ([(EVECallListCallsItem*) obj type] == EVECallTypeCharacter);
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
		int32_t accessMask = self.account.apiKey.apiKeyInfo.key.accessMask;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.sections = sections;
			self.accessMask = accessMask;
			completionBlock(nil);
		});
	}];
}


@end

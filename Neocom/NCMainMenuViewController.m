//
//  NCMainMenuViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMainMenuViewController.h"
#import "NCStorage.h"
#import "NCTableViewEmptyHedaerView.h"
#import "NCSideMenuViewController.h"

@interface NCMainMenuViewController ()
@property (nonatomic, strong) NSMutableArray* allSections;
@property (nonatomic, strong) NSMutableArray* sections;
- (void) reload;
@end

@implementation NCMainMenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	[self.tableView registerClass:[NCTableViewEmptyHedaerView class] forHeaderFooterViewReuseIdentifier:@"NCTableViewEmptyHedaerView"];
	self.allSections = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mainMenu" ofType:@"plist"]];
	[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	
	cell.textLabel.text = row[@"title"];
	cell.imageView.image = [UIImage imageNamed:row[@"image"]];
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
	return @"title";
}

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewEmptyHedaerView"];
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = self.sections[indexPath.section][indexPath.row];
	[self performSegueWithIdentifier:row[@"segueIdentifier"] sender:[tableView cellForRowAtIndexPath:indexPath]];
	
//	[self.sideMenuViewController setContentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"NCCharacterSheetViewController"] animated:YES];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reload];
}

#pragma mark - Private

- (void) reload {
	NCAccount* account = [NCAccount currentAccount];
	NSInteger apiKeyAccessMask = account.apiKey.apiKeyInfo.key.accessMask;
	NSString* accessMaskKey = account.accountType == NCAccountTypeCorporate ? @"corpAccessMask" : @"charAccessMask" ;
	
	self.sections = [NSMutableArray new];
	for (NSArray* rows in self.allSections) {
		NSMutableArray* section = [NSMutableArray new];
		for (NSDictionary* row in rows) {
			NSInteger accessMask = [[row valueForKey:accessMaskKey] integerValue];
			if ((accessMask & apiKeyAccessMask) == accessMask) {
				[section addObject:row];
			}
		}
		if (section.count > 0)
			[self.sections addObject:section];
	}
	[self.tableView reloadData];
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
										 }
							 completionHandler:^(NCTask *task) {
								 
							 }];
}

@end

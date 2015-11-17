//
//  NCRSSViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCRSSViewController.h"
#import "NCTableViewCell.h"
#import "NCRSSFeedViewController.h"

@interface NCRSSViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCRSSViewController

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
	self.sections = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"rssFeeds" ofType:@"plist"]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCRSSFeedViewController"]) {
		NCRSSFeedViewController* destinationViewController = segue.destinationViewController;
		NSDictionary* feed = [sender object];
		destinationViewController.title = feed[@"title"];
		destinationViewController.url = [NSURL URLWithString:feed[@"url"]];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section][@"feeds"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
    NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
	NSDictionary* feed = self.sections[indexPath.section][@"feeds"][indexPath.row];
	cell.iconView.image = [UIImage imageNamed:@"rss"];
	cell.titleLabel.text = feed[@"title"];
	cell.object = feed;
}

@end

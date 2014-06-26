//
//  NCSkillPlanImportViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlanImportViewController.h"
#import "ASHTTPServer.h"
#import "UIDevice+IP.h"
#import "NCTableViewCell.h"
#import "NCSkillPlanViewController.h"
#import "NSData+Neocom.h"

@interface NCSkillPlanImportViewController ()<ASHTTPServerDelegate>
@property (nonatomic, strong) ASHTTPServer* server;
@property (nonatomic, strong) NSString* address;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCSkillPlanImportViewController

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
	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
	
	NSMutableArray* rows = [[NSMutableArray alloc] init];
	for (NSString* file in files) {
		NSString* extension = [file pathExtension];
		if ([extension compare:@"emp" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
			([extension compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame && ![file isEqualToString:@"exportedFits.xml"]))
			[rows addObject:file];
	}
	[rows sortUsingSelector:@selector(compare:)];
	self.rows = rows;
	
	self.server = [[ASHTTPServer alloc] initWithName:NSLocalizedString(@"Neocom", nil) port:8080];
	self.server.delegate = self;
	NSError* error = nil;
	if ([self.server startWithError:&error]) {
		NSString* address = [UIDevice localIPAddress];
		if (address) {
			self.address = [NSString stringWithFormat:@"http://%@:8080", address];
			return;
		}
	}
	self.address = NSLocalizedString(@"Check your Wi-Fi settings", nil);
	self.server = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCSkillPlanViewController"]) {
		NCSkillPlanViewController* destinationViewController = segue.destinationViewController;
		if ([sender isKindOfClass:[NCTableViewCell class]]) {
			NSString* fileName = [sender object];
			NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:fileName];
			if ([[fileName pathExtension] compare:@"emp" options:NSCaseInsensitiveSearch] == NSOrderedSame)
				destinationViewController.xmlData = [NSData dataWithCompressedContentsOfFile:path];
			else
				destinationViewController.xmlData = [NSData dataWithContentsOfFile:path];
			destinationViewController.skillPlanName = [fileName stringByDeletingPathExtension];
		}
		else {
			destinationViewController.xmlData = sender[@"data"];
			destinationViewController.skillPlanName = sender[@"name"];
		}
	}
}

#pragma mark - Table view data source

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 1 ? NSLocalizedString(@"Documents", nil) : nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"URLCell" forIndexPath:indexPath];
		cell.detailTextLabel.text = self.address;
		return cell;
	}
	else {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		NSString* file = self.rows[indexPath.row];
		cell.object = file;
		cell.titleLabel.text = file;
		return cell;
	}
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return section == 1 ? 28 : 0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

#pragma mark - ASHTTPServerDelegate

- (void) server:(ASHTTPServer*) server didReceiveRequest:(NSURLRequest*) request {
	NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"evemon" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];

	NSDictionary* arguments = request.arguments;
	if (arguments.count > 0) {
		NSDictionary* skillPlan = arguments[@"skillPlan"];
		NSData* data = [skillPlan[@"value"] uncompressedData];
		NSString* name = skillPlan[@"fileName"];
		if (data) {
			if (!name)
				name = NSLocalizedString(@"Skill Plan", nil);
			[self performSegueWithIdentifier:@"NCSkillPlanViewController" sender:@{@"name": name, @"data": data}];
			[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Success", nil) options:0 range:NSMakeRange(0, page.length)];
		}
		else
			[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Invalid file format", nil) options:0 range:NSMakeRange(0, page.length)];
	}
	else {
		[page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
	}
	
	NSData* bodyData = nil;
	bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
	NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
															  statusCode:200
																bodyData:bodyData
															headerFields:nil];
	[server finishRequest:request withResponse:response];
}

@end

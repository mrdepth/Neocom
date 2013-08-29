//
//  SkillPlannerImportViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerImportViewController.h"
#import "Globals.h"
#import "UITableViewCell+Nib.h"
#import "SkillPlanViewController.h"
#import "UIDevice+IP.h"
#import "SkillPlan.h"
#import "EVEAccount.h"
#import "GroupedCell.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface SkillPlannerImportViewController()
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSArray* addresses;
@property (nonatomic, strong) EUHTTPServer* server;

- (void) updateAddress;

@end

@implementation SkillPlannerImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	[self.server shutdown];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.title = NSLocalizedString(@"Import", nil);
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)]];

	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:[Globals documentsDirectory]];
	self.rows = [[NSMutableArray alloc] init];
	for (NSString* file in files)
		if ([[file pathExtension] compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame && ![file isEqualToString:@"exportedFits.xml"])
			[self.rows addObject:file];
	[self performSelector:@selector(updateAddress) withObject:nil afterDelay:0];
	
	self.server = [[EUHTTPServer alloc] initWithDelegate:self];
	[self.server run];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	self.rows = nil;
	
	[self.server shutdown];
	self.server = nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? self.addresses.count : self.rows.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"Cell";
	
	GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	
	if (indexPath.section == 0) {
		cell.textLabel.text = [NSString stringWithFormat:@"http://%@:8080", [self.addresses objectAtIndex:indexPath.row]];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		cell.textLabel.text = [[self.rows objectAtIndex:indexPath.row] stringByDeletingPathExtension];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 0 ? NSLocalizedString(@"Import via Internet Browser", nil) : NSLocalizedString(@"Skill Plans", nil);
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		view.collapsImageView.hidden = YES;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1) {
		EUOperation* operation = [EUOperation operationWithIdentifier:@"SkillPlannerImportViewController+Load" name:NSLocalizedString(@"Importing Skill Plan", nil)];
		__weak EUOperation* weakOperation = operation;
		__block SkillPlan* skillPlan = nil;
		[operation addExecutionBlock:^(void) {
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account)
				return;

			skillPlan = [SkillPlan skillPlanWithAccount:account
									 eveMonSkillPlanPath:[[Globals documentsDirectory] stringByAppendingPathComponent:[self.rows objectAtIndex:indexPath.row]]];
			weakOperation.progress = 0.5;
			[skillPlan trainingTime];
			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			if (![weakOperation isCancelled]) {
				SkillPlanViewController* controller = [[SkillPlanViewController alloc] initWithNibName:@"SkillPlanViewController" bundle:nil];
				controller.skillPlan = skillPlan;
				controller.skillPlannerImportViewController = self;
				[self.navigationController pushViewController:controller animated:YES];
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark EUHTTPServerDelegate

- (void) server:(EUHTTPServer*) server didReceiveRequest:(EUHTTPRequest*) request connection:(EUHTTPConnection*) connection {
	BOOL canRun = YES;
	
	NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"evemon" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
	NSDictionary* arguments = request.arguments;
	
	if (arguments.count > 0) {
		NSDictionary* argument = [arguments valueForKey:@"skillPlan"];
		if (!argument || ![argument isKindOfClass:[NSDictionary class]]) {
			[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"File format error", nil) options:0 range:NSMakeRange(0, page.length)];
		}
		else {
			canRun = NO;
		}
	}
	else {
		[page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
	}
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
	connection.response.message = message;
	CFRelease(message);
	
	if (canRun) {
		CFHTTPMessageSetBody(connection.response.message, (__bridge CFDataRef)[page dataUsingEncoding:NSUTF8StringEncoding]);
		[connection.response run];
	}
	else {
		__block SkillPlan* skillPlan = nil;
		EUOperation *operation = [EUOperation operationWithIdentifier:@"SkillPlannerImportViewController+didReceiveRequest" name:NSLocalizedString(@"Processing Request", nil)];
		__weak EUOperation* weakOperation = operation;
		[operation addExecutionBlock:^{
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account)
				return;
			
			skillPlan = [SkillPlan skillPlanWithAccount:account eveMonSkillPlan:[[arguments valueForKey:@"skillPlan"] valueForKey:@"value"]];
			weakOperation.progress = 0.5;
			
			if (skillPlan) {
				[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Check your device for the next step", nil) options:0 range:NSMakeRange(0, page.length)];
				[skillPlan trainingTime];
			}
			else
				[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"File format error", nil) options:0 range:NSMakeRange(0, page.length)];

			weakOperation.progress = 1.0;
		}];
		
		[operation setCompletionBlockInMainThread:^(void) {
			NSData* bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
			CFHTTPMessageSetBody(connection.response.message, (__bridge CFDataRef) bodyData);
			CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef) @"Content-Length", (__bridge CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
			CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef) @"Content-Type", (__bridge CFStringRef) @"text/html; charset=UTF-8");

			[connection.response run];
			if (skillPlan) {
				if (self.navigationController.visibleViewController == self) {
					SkillPlanViewController* controller = [[SkillPlanViewController alloc] initWithNibName:@"SkillPlanViewController" bundle:nil];
					controller.skillPlan = skillPlan;
					controller.skillPlannerImportViewController = self;
					[self.navigationController pushViewController:controller animated:YES];
				}
			}

		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

#pragma mark - Private

- (void) updateAddress {
	self.addresses = [UIDevice localIPAddresses];
	if (self.addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
	}
	else {
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
}

@end

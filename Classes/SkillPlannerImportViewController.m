//
//  SkillPlannerImportViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SkillPlannerImportViewController.h"
#import "Globals.h"
#import "CharacterCellView.h"
#import "NibTableViewCell.h"
#import "SkillPlanViewController.h"
#import "UIDevice+IP.h"
#import "SkillPlan.h"
#import "EVEAccount.h"

@interface SkillPlannerImportViewController(Private)

- (void) updateAddress;

@end

@implementation SkillPlannerImportViewController
@synthesize plansTableView;
@synthesize delegate;

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
	[server shutdown];
	[server release];

	[plansTableView release];
	[rows release];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Import";
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];

	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:[Globals documentsDirectory]];
	rows = [[NSMutableArray alloc] init];
	for (NSString* file in files)
		if ([[file pathExtension] compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame && ![file isEqualToString:@"exportedFits.xml"])
			[rows addObject:file];
	[self performSelector:@selector(updateAddress) withObject:nil afterDelay:0];
	
	server = [[EUHTTPServer alloc] initWithDelegate:self];
	[server run];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	self.plansTableView = nil;
	[rows release];
	rows = nil;
	
	[server shutdown];
	[server release];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 0 ? addresses.count : rows.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"CharacterCellView";
	
	CharacterCellView *cell = (CharacterCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [CharacterCellView cellWithNibName:@"CharacterCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	if (indexPath.section == 0) {
		cell.characterNameLabel.text = [NSString stringWithFormat:@"http://%@:8080", [addresses objectAtIndex:indexPath.row]];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		cell.characterNameLabel.text = [[rows objectAtIndex:indexPath.row] stringByDeletingPathExtension];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 0 ? @"Import via Internet Browser" : @"Skill Plans";
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = title;
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1) {
		__block EUSingleBlockOperation* operation = [EUSingleBlockOperation operationWithIdentifier:@"SkillPlannerImportViewController+Load"];
		__block SkillPlan* skillPlan = nil;
		[operation addExecutionBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account) {
				[pool release];
				return;
			}

			skillPlan = [[SkillPlan skillPlanWithAccount:account
									 eveMonSkillPlanPath:[[Globals documentsDirectory] stringByAppendingPathComponent:[rows objectAtIndex:indexPath.row]]] retain];
			
			[skillPlan trainingTime];
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			if (![operation isCancelled]) {
				SkillPlanViewController* controller = [[SkillPlanViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"SkillPlanViewController-iPad" : @"SkillPlanViewController")
																								bundle:nil];
				controller.skillPlan = skillPlan;
				controller.skillPlannerImportViewController = self;
				[self.navigationController pushViewController:controller animated:YES];
				[controller release];
			}
			[skillPlan release];
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
			[page replaceOccurrencesOfString:@"{error}" withString:@"File format error" options:0 range:NSMakeRange(0, page.length)];
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
		CFHTTPMessageSetBody(connection.response.message, (CFDataRef)[page dataUsingEncoding:NSUTF8StringEncoding]);
		[connection.response run];
	}
	else {
		__block SkillPlan* skillPlan = nil;
		NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			EVEAccount *account = [EVEAccount currentAccount];
			if (!account) {
				[pool release];
				return;
			}

			skillPlan = [[SkillPlan skillPlanWithAccount:account eveMonSkillPlan:[[arguments valueForKey:@"skillPlan"] valueForKey:@"value"]] retain];
			if (skillPlan) {
				[page replaceOccurrencesOfString:@"{error}" withString:@"Check your device for the next step" options:0 range:NSMakeRange(0, page.length)];
				[skillPlan trainingTime];
			}
			else
				[page replaceOccurrencesOfString:@"{error}" withString:@"File format error" options:0 range:NSMakeRange(0, page.length)];

			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			NSData* bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
			CFHTTPMessageSetBody(connection.response.message, (CFDataRef) bodyData);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Type", (CFStringRef) @"text/html; charset=UTF-8");

			[connection.response run];
			if (skillPlan) {
				if (self.navigationController.visibleViewController == self) {
					SkillPlanViewController* controller = [[SkillPlanViewController alloc] initWithNibName:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"SkillPlanViewController-iPad" : @"SkillPlanViewController")
																									bundle:nil];
					controller.skillPlan = skillPlan;
					controller.skillPlannerImportViewController = self;
					[self.navigationController pushViewController:controller animated:YES];
					[controller release];
				}
				[skillPlan release];
			}

		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

@end

@implementation SkillPlannerImportViewController(Private)

- (void) updateAddress {
	if (addresses)
		[addresses release];
	addresses = [[UIDevice localIPAddresses] retain];
	if (addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
	}
	else {
		[plansTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
}

@end

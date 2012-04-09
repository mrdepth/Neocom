//
//  FittingExportViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.04.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//

#import "FittingExportViewController.h"
#import "UIDevice+IP.h"
#import "EUOperationQueue.h"
#import "Globals.h"
#import "EVEDBAPI.h"
#import "Fit.h"
#import "ItemInfo.h"
#import "NSArray+GroupBy.h"
#include "eufe.h"

@interface FittingExportViewController (Private)

- (void) updateAddress;

@end

@implementation FittingExportViewController
@synthesize addressLabel;

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
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(onClose:)] autorelease]];
	self.title = @"Export";
	
	NSMutableArray* fitsTmp = [NSMutableArray array];
	NSMutableString* eveXML = [NSMutableString string];
	NSMutableString *pageTmp = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fits" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
	
	[eveXML appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSMutableArray *fitsArray = [NSMutableArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[Globals fitsFilePath]]];
				
		eufe::Engine* fittingEngine = new eufe::Engine([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]);
		boost::shared_ptr<eufe::Character> *character = new boost::shared_ptr<eufe::Character>(new eufe::Character(fittingEngine));

		for (NSMutableDictionary* row in [NSArray arrayWithArray:fitsArray]) {
			if ([[row valueForKey:@"isPOS"] boolValue]) {
				[fitsArray removeObject:row];
				continue;
			}
			
			Fit* fit = [[Fit alloc] initWithDictionary:row character:*character];
			ItemInfo* type = [EVEDBInvType invTypeWithTypeID:[[row valueForKeyPath:@"fit.shipID"] integerValue] error:nil]; 
			
			if (type) {
				NSString* fitString = fit.eveXML;
				[row setValue:type forKey:@"type"];
				[row setValue:[type typeSmallImageName] forKey:@"imageName"];
				[row setValue:fitString forKey:@"xml"];
				[row setValue:fit.dna forKey:@"dna"];
				[eveXML appendString:fitString];
			}
			[fit release];
		}
		
		[fitsArray sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"shipName" ascending:YES]]];
		[fitsTmp addObjectsFromArray:[fitsArray arrayGroupedByKey:@"type.groupID"]];
		[fitsTmp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSDictionary* a = [obj1 objectAtIndex:0];
			NSDictionary* b = [obj2 objectAtIndex:0];
			return [[a valueForKeyPath:@"type.group.groupName"] compare:[b valueForKeyPath:@"type.group.groupName"]];
		}];
		
		NSMutableString* body = [NSMutableString string];
		NSInteger groupID = 0;
		for (NSArray* group in fitsTmp) {
			NSString* groupName = [[group objectAtIndex:0] valueForKeyPath:@"type.group.groupName"];
			[body appendFormat:@"<tr><td colspan=4 class=\"group\"><b>%@</b></td></tr>\n", groupName];
			NSInteger fitID = 0;
			for (NSDictionary* fit in group) {
				EVEDBInvType* type = [fit valueForKey:@"type"];
				[body appendFormat:@"<tr><td class=\"icon\"><image src=\"%@\" width=32 height=32 /></td><td width=\"20%%\">%@</td><td>%@</td><td width=\"30%%\">Download <a href=\"%d_%d.xml\">EVE XML file</a> or <a href=\"javascript:CCPEVE.showFitting('%@');\"'>Show Fitting</a> ingame</td></tr>\n",
				 type.typeSmallImageName, type.typeName, [fit valueForKey:@"fitName"], groupID, fitID, [fit valueForKey:@"dna"]];
				fitID++;
			}
			groupID++;
		}
		
		[pageTmp replaceOccurrencesOfString:@"{body}" withString:body options:0 range:NSMakeRange(0, pageTmp.length)];

		delete character;
		delete fittingEngine;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[eveXML appendString:@"</fittings>"];
		NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"exportedFits.xml"];
		[eveXML writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
		
		[fits release];
		fits = [fitsTmp retain];
		
		[page release];
		page = [pageTmp retain];
		
		[server release];
		server = [[EUHTTPServer alloc] initWithDelegate:self];
		[server run];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	
	[self updateAddress];	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.addressLabel = nil;
	[server shutdown];
	[server release];
	server = nil;
	[fits release];
	fits = nil;
	[page release];
	page = nil;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];

    // Release any retained subviews of the main view.
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	[addressLabel release];
	
	[server shutdown];
	[server release];
	
	[fits release];
	[page release];
    [super dealloc];
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

#pragma mark EUHTTPServerDelegate

- (void) server:(EUHTTPServer*) server didReceiveRequest:(EUHTTPRequest*) request connection:(EUHTTPConnection*) connection {
	NSURL* url = request.url;
	NSString* path = [url path];
	NSString* extension = [path pathExtension];

	if ([extension compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil]];
		CFHTTPMessageRef message;
		if (data) {
			message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFHTTPMessageSetBody(connection.response.message, (CFDataRef)data);
			CFRelease(message);
		}
		else {
			message = CFHTTPMessageCreateResponse(NULL, 404, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
		}
		[connection.response run];
	}
	else if ([extension compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		NSArray* components = [[[path lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
		NSString* xml = nil;
		NSString* typeName = nil;
		if (components.count == 2) {
			NSInteger groupID = [[components objectAtIndex:0] integerValue];
			NSInteger fitID = [[components objectAtIndex:1] integerValue];
			if (fits.count > groupID) {
				NSArray* group = [fits objectAtIndex:groupID];
				if (group.count > fitID) {
					NSDictionary* fit = [group objectAtIndex:fitID];
					xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" ?>\n<fittings>\n%@</fittings>", [fit valueForKey:@"xml"]];
					typeName = [fit valueForKeyPath:@"type.typeName"];
				}
			}
		}
		else if ([[path lastPathComponent] compare:@"allFits.xml" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			NSString* path = [[Globals documentsDirectory] stringByAppendingPathComponent:@"exportedFits.xml"];
			xml = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
			typeName = @"allFits";
		}
		
		CFHTTPMessageRef message;
		if (xml) {
			CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
			CFHTTPMessageSetBody(connection.response.message, (CFDataRef)[xml dataUsingEncoding:NSUTF8StringEncoding]);
			CFHTTPMessageSetHeaderFieldValue(connection.response.message, (CFStringRef) @"Content-Type", (CFStringRef) @"application/xml");
			CFHTTPMessageSetHeaderFieldValue(connection.response.message,
											 (CFStringRef) @"Content-Disposition",
											 (CFStringRef) [NSString stringWithFormat:@"attachment; filename=\"%@.xml\"", typeName]);
		}
		else {
			message = CFHTTPMessageCreateResponse(NULL, 404, NULL, kCFHTTPVersion1_0);
			connection.response.message = message;
			CFRelease(message);
		}
		[connection.response run];
	}
	else {
		CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
		connection.response.message = message;
		CFRelease(message);
		CFHTTPMessageSetBody(connection.response.message, (CFDataRef)[page dataUsingEncoding:NSUTF8StringEncoding]);
		[connection.response run];
	}
}

@end

@implementation FittingExportViewController(Private)

- (void) updateAddress {
	NSArray *addresses = [UIDevice localIPAddresses];
	if (addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
		self.addressLabel.text = @"Unknown IP Address";
	}
	else {
		NSMutableString *text = [NSMutableString string];
		for (NSString *ip in addresses)
			[text appendFormat:@"http://%@:8080\n", ip];
		self.addressLabel.text = text;
		CGRect r = CGRectMake(self.addressLabel.frame.origin.x, self.addressLabel.frame.origin.y, self.addressLabel.frame.size.width, 100);
		r = [self.addressLabel textRectForBounds:r limitedToNumberOfLines:0];
		r.origin = self.addressLabel.frame.origin;
		r.size.width = self.addressLabel.frame.size.width;
		r.size.height += 20;
		self.addressLabel.frame = r;
	}
}

@end

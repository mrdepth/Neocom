//
//  NCFittingExportViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 13.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingExportViewController.h"
#import "ASHTTPServer.h"
#import "UIDevice+IP.h"
#import "NCStorage.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCDatabase.h"
#import "NSArray+Neocom.h"
#import "UIColor+Neocom.h"
#import "NCLoadoutsParser.h"
#import "UIAlertView+Block.h"
#import "NCStorage.h"

@interface NCFittingExportViewControllerRow : NSObject
@property (nonatomic, strong) NSManagedObjectID* loadoutID;
@property (nonatomic, strong) NSString* eveXMLRepresentation;
@property (nonatomic, strong) NSString* eveXMLRecordRepresentation;
@property (nonatomic, strong) NSString* dnaRepresentation;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) NSString* iconFile;
@property (nonatomic, assign) NCLoadoutCategory category;

@end

@implementation NCFittingExportViewControllerRow

@end

@interface NCFittingExportViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, assign) int32_t groupID;
@property (nonatomic, strong) NSString* title;
@end

@implementation NCFittingExportViewControllerSection
@end



@interface NCFittingExportViewController ()<ASHTTPServerDelegate>
@property (nonatomic, strong) ASHTTPServer* server;
@property (nonatomic, strong) NSString* html;
@property (nonatomic, strong) NSMutableArray* fits;
@property (nonatomic, strong) NSString* allFits;

- (void) reloadWithCompletionHandler:(void(^)()) completionHandler;
- (void) performImportLoadouts:(NSArray*) loadouts withCompletionHandler:(void(^)()) completionHandler;
@end

@implementation NCFittingExportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor appearanceTableViewBackgroundColor];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.server = [[ASHTTPServer alloc] initWithName:NSLocalizedString(@"Neocom", nil) port:8080];
	self.server.delegate = self;
	NSError* error = nil;
	
	NSString* address = nil;
	if ([self.server startWithError:&error]) {
		address = [UIDevice localIPAddress];
	}
	
	if (address) {
		self.urlLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Your address is\nhttp://%@:8080", nil), address];
	}
	else {
		self.urlLabel.text = NSLocalizedString(@"Check your Wi-Fi settings", nil);
		self.server = nil;
	}
	

	[self reloadWithCompletionHandler:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.server = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClose:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ASHTTPServerDelegate

- (void) server:(ASHTTPServer*) server didReceiveRequest:(NSURLRequest*) request {
	__block NSData* bodyData = nil;
	NSString* path = [request.URL.path lowercaseString];
	NSString* extension = path.pathExtension;
	
	NSMutableDictionary* headerFields = [NSMutableDictionary new];
	NSInteger statusCode = 404;
	
	if ([extension isEqualToString:@"png"]) {
		NCDBEveIcon* icon = [self.databaseManagedObjectContext eveIconWithIconFile:[path lastPathComponent]];
		if (icon) {
			UIImage* image = icon.image.image;
			bodyData = UIImagePNGRepresentation(image);
			headerFields[@"Content-Type"] = @"image/png";
			statusCode = 200;
		}
	}
	else if ([extension isEqualToString:@"xml"]) {
		if ([[path lastPathComponent] isEqualToString:@"allfits.xml"]) {
			statusCode = 200;
			bodyData = [self.allFits dataUsingEncoding:NSUTF8StringEncoding];
		}
		else {
			NSArray* c = [[[path lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"_"];
			if (c.count == 2) {
				NSInteger i = [[c lastObject] integerValue] - 1;
				if (i >= 0 && i < self.fits.count) {
					NSString* fit = self.fits[i];
					statusCode = 200;
					bodyData = [fit dataUsingEncoding:NSUTF8StringEncoding];
				}
			}
		}
		if (statusCode == 200) {
			headerFields[@"Content-Type"] = @"application/xml";
			headerFields[@"Content-Disposition"] = [NSString stringWithFormat:@"attachment; filename=\"%@\"", [path lastPathComponent]];
		}
	}
	else {
		if ([[[path lastPathComponent] lowercaseString] isEqualToString:@"upload"]) {
			NSString* contentType = request.allHTTPHeaderFields[@"Content-Type"];
			NSString* boundary;
			for (NSString* record in [contentType componentsSeparatedByString:@";"]) {
				NSArray* components = [record componentsSeparatedByString:@"="];
				if (components.count == 2) {
					NSString* key = [components[0] lowercaseString];
					if ([key rangeOfString:@"boundary"].location != NSNotFound) {
						boundary = components[1];
					}
				}
			}
			if (boundary) {
				NSString* endMarker = [NSString stringWithFormat:@"--%@--", boundary];
				NSString* bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
				NSInteger start = [bodyString rangeOfString:@"\r\n\r\n"].location;
				NSInteger end = [bodyString rangeOfString:endMarker].location;
				if (start != NSNotFound && end != NSNotFound && start + 4 < end) {
					NSString* xml = [bodyString substringWithRange:NSMakeRange(start + 4, end - start - 4)];
					NSArray* loadouts = [NCLoadoutsParser parserEveXML:xml];
					if (loadouts.count > 0) {
						[self performImportLoadouts:loadouts withCompletionHandler:^{
							[self reloadWithCompletionHandler:^{
								headerFields[@"Content-Type"] = @"text/html; charset=UTF-8";
								bodyData = [self.html dataUsingEncoding:NSUTF8StringEncoding];
								
								headerFields[@"Content-Length"] = [NSString stringWithFormat:@"%ld", (long) bodyData.length];
								
								NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
																						  statusCode:200
																							bodyData:bodyData
																						headerFields:headerFields];
								[server finishRequest:request withResponse:response];
							}];
						}];
						return;
					}
				}
			}
			[[UIAlertView alertViewWithTitle:NSLocalizedString(@"Error", nil)
									 message:NSLocalizedString(@"Invalid file format", nil)
						   cancelButtonTitle:NSLocalizedString(@"Close", nil)
						   otherButtonTitles:nil
							 completionBlock:nil
								 cancelBlock:nil] show];
		}
		statusCode = 200;
		headerFields[@"Content-Type"] = @"text/html; charset=UTF-8";
		bodyData = [self.html dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	headerFields[@"Content-Length"] = [NSString stringWithFormat:@"%ld", (long) bodyData.length];
	
	NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
															  statusCode:statusCode
																bodyData:bodyData
															headerFields:headerFields];
	[server finishRequest:request withResponse:response];
}

#pragma mark - Private

- (void) reloadWithCompletionHandler:(void(^)()) completionHandler {
	NSMutableString* htmlTemplate = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fits" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	NSString* headerTemplate;
	NSString* rowTemplate;
	
	
	NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:@"\\{header\\}(.*)\\{/header\\}"
																				options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																				  error:nil];
	NSTextCheckingResult* result = [expression firstMatchInString:htmlTemplate options:0 range:NSMakeRange(0, htmlTemplate.length)];
	if (result.numberOfRanges == 2) {
		headerTemplate = [htmlTemplate substringWithRange:[result rangeAtIndex:1]];
		[htmlTemplate replaceCharactersInRange:[result rangeAtIndex:0] withString:@""];
	}
	
	expression = [NSRegularExpression regularExpressionWithPattern:@"\\{row\\}(.*)\\{/row\\}"
														   options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
															 error:nil];
	result = [expression firstMatchInString:htmlTemplate options:0 range:NSMakeRange(0, htmlTemplate.length)];
	if (result.numberOfRanges == 2) {
		rowTemplate = [htmlTemplate substringWithRange:[result rangeAtIndex:1]];
		[htmlTemplate replaceCharactersInRange:[result rangeAtIndex:0] withString:@""];
	}
	
	NSManagedObjectContext* storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		NSMutableArray* loadouts = [NSMutableArray new];
		for (NCLoadout* loadout in [storageManagedObjectContext loadouts]) {
			NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:loadout];
			NCFittingExportViewControllerRow* row = [NCFittingExportViewControllerRow new];
			row.loadoutID = [loadout objectID];
			row.loadoutName = loadout.name;
			row.typeID = loadout.typeID;
			row.eveXMLRepresentation = fit.eveXMLRepresentation;
			row.eveXMLRecordRepresentation = fit.eveXMLRecordRepresentation;
			row.dnaRepresentation = fit.dnaRepresentation;
			[loadouts addObject:row];
		};
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[databaseManagedObjectContext performBlock:^{
			NSMutableDictionary* shipLoadouts = [NSMutableDictionary new];
			for (NCFittingExportViewControllerRow* row in loadouts) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:row.typeID];
				row.typeName = type.typeName;
				row.iconFile = [type.icon iconFile];
				if (type && type.group.category.categoryID == NCCategoryIDShip) {
					row.category = NCLoadoutCategoryShip;
					NCFittingExportViewControllerSection* section = shipLoadouts[@(type.group.groupID)];
					if (!section) {
						section = [NCFittingExportViewControllerSection new];
						shipLoadouts[@(type.group.groupID)] = section;
						section.title = type.group.groupName;
						section.groupID = type.group.groupID;
						section.rows = [NSMutableArray new];
					}
					[section.rows addObject:row];
				}
			}
			NSMutableArray* sections = [[[shipLoadouts allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]] mutableCopy];
			
			for (NCFittingExportViewControllerSection* section in sections) {
				[section.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
//				[fits addObjectsFromArray:section.rows];
			}
			
			NSMutableArray* fits = [NSMutableArray new];
			NSMutableString* allFits = [NSMutableString new];
			[allFits appendString:@"<?xml version=\"1.0\" ?>\n<fittings>\n"];

			NSMutableString* body = [NSMutableString new];
			int32_t i = 0;
			for (NCFittingExportViewControllerSection* section in sections) {
				[body appendFormat:headerTemplate, section.title];
				for (NCFittingExportViewControllerRow* row in section.rows) {
					[fits addObject:row.eveXMLRepresentation];
					[allFits appendString:row.eveXMLRecordRepresentation];
					[body appendFormat:rowTemplate,
					 row.iconFile, row.typeName, row.loadoutName, row.typeID, ++i, row.dnaRepresentation];
				}
			}
			
			[allFits appendString:@"</fittings>"];
			[htmlTemplate replaceOccurrencesOfString:@"{body}" withString:body options:0 range:NSMakeRange(0, htmlTemplate.length)];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.html = htmlTemplate;
				self.fits = fits;
				self.allFits = allFits;
				if (completionHandler)
					completionHandler();
			});
		}];
	}];
}

- (void) performImportLoadouts:(NSArray*) loadouts withCompletionHandler:(void(^)()) completionHandler {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Do you wish to import %ld loadouts?", nil), (long) loadouts.count] preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		for (NCLoadout* loadout in loadouts) {
			[self.storageManagedObjectContext insertObject:loadout];
			[self.storageManagedObjectContext insertObject:loadout.data];
		}
		NSError* error = nil;
		[self.storageManagedObjectContext save:&error];
		if (completionHandler)
			completionHandler();
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		if (completionHandler)
			completionHandler();
	}]];
	[self presentViewController:controller animated:YES completion:nil];
}

@end

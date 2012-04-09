//
//  FittingExportViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.04.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUHTTPServer.h"

@interface FittingExportViewController : UIViewController<EUHTTPServerDelegate> {
	UILabel *addressLabel;
@private
	EUHTTPServer *server;
	NSArray* fits;
	NSString* page;
}
@property (nonatomic, retain) IBOutlet UILabel *addressLabel;

- (IBAction) onClose:(id)sender;

@end

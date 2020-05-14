//
//  NCFittingCRESTFitExportViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 06.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingCRESTAccountsViewController.h"

@class CRFitting;
@interface NCFittingCRESTFitExportViewController : NCFittingCRESTAccountsViewController
@property (nonatomic, strong) CRFitting* fitting;
@end

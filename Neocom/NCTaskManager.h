//
//  NCTaskManager.h
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCTask.h"

#define NCTaskManagerIdentifierNone nil
#define NCTaskManagerIdentifierAuto [NSString stringWithFormat:@"%@.%@", NSStringFromClass(self.class), NSStringFromSelector(_cmd)]
#define NCTaskManagerDefaultTitle NSLocalizedString(@"Loading", nil)

@class NCTask;
@interface NCTaskManager : NSOperationQueue
@property (nonatomic, weak, readonly) UIViewController* viewController;
@property (nonatomic, assign) BOOL active;

- (id) initWithViewController:(UIViewController*) viewController;
- (void) addTaskWithIndentifier:(NSString*) identifier
						  title:(NSString*) title
						  block:(void(^)(NCTask* task)) block
			  completionHandler:(void(^)(NCTask* task)) completionHandler;

@end

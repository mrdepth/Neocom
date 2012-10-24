//
//  EUOperation.h
//  EUOperationQueue
//
//  Created by Artem Shimanski on 28.08.12.
//  Copyright (c) 2012 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUOperation;
@protocol EUOperationDelegate <NSObject>
- (void) operationDidStart:(EUOperation*)operation;
- (void) operation:(EUOperation*)operation didUpdateProgress:(float) progress;
- (void) operationDidFinish:(EUOperation*)operation;
@end

@interface EUOperation : NSBlockOperation
@property (nonatomic, readonly, retain) NSString* identifier;
@property (nonatomic) float progress;
@property (nonatomic, copy) NSString* operationName;
@property (nonatomic, assign) id<EUOperationDelegate> delegate;

+ (id) operationWithIdentifier:(NSString*) aIdentifier name:(NSString*) name;
+ (id) operationWithIdentifier:(NSString*) aIdentifier;
+ (id) operation;

- (id) initWithIdentifier:(NSString*) aIdentifier name:(NSString*) name;
- (id) initWithIdentifier:(NSString*) aIdentifier;

- (void) setCompletionBlockInCurrentThread:(void (^)(void))block;

@end

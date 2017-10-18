//
//  NCPieChartView.h
//  Neocom
//
//  Created by Артем Шиманский on 17.11.15.
//  Copyright © 2015 Shimanski Artem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCPieChartSegment : NSObject
@property (nonatomic, assign) double value;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) NSNumberFormatter* numberFormatter;

+ (instancetype) segmentWithValue:(double) value color:(UIColor*) color numberFormatter:(NSNumberFormatter*) numberFormatter;
- (id) initWithValue:(double) value color:(UIColor*) color numberFormatter:(NSNumberFormatter*) numberFormatter;

@end

@interface NCPieChartView : UIView

- (void) addSegment:(NCPieChartSegment*) segment animated:(BOOL) animated;
- (void) clear;

@end

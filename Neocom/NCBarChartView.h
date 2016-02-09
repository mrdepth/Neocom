//
//  NCBarChartView.h
//  Neocom
//
//  Created by Артем Шиманский on 18.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCBarChartSegment : NSObject
@property (nonatomic, assign) double x;
@property (nonatomic, assign) double w;
@property (nonatomic, assign) double h0;
@property (nonatomic, assign) double h1;
@property (nonatomic, strong) UIColor* color0;
@property (nonatomic, strong) UIColor* color1;
@end

@interface NCBarChartView : UIView

- (void) addSegment:(NCBarChartSegment*) segment;
- (void) addSegments:(NSArray*) segments;
- (void) clear;
@end

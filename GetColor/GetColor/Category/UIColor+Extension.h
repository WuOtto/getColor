//
//  UIColor+Extension.h
//  GetColor
//
//  Created by otto on 2017/8/17.
//  Copyright © 2017年 otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)

+(NSArray *)getRgbByColor:(UIColor *)color;
+(NSString*)toStrByUIColor:(UIColor*)color;
+(UIColor *)getColorStr:(NSString *)hexColor;

@end

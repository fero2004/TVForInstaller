//
//  ComminUtility.m
//  TVForInstaller
//
//  Created by AlienLi on 15/5/19.
//  Copyright (c) 2015年 AlienLi. All rights reserved.
//

#import "ComminUtility.h"
#import <UIKit/UIKit.h>

@implementation ComminUtility

+(void)configureTitle:(NSString*)title forViewController:(UIViewController*)viewController{

    viewController.title = title;
    
    [viewController.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:19.0/255 green:86./255 blue:115./255 alpha:1.0]];
    //    viewController.navigationController.navigationBar.opaque = YES;
    
    [viewController.navigationController.navigationBar setBackgroundImage:[self imageWithView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)]] forBarMetrics:UIBarMetricsDefault];
    [viewController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    UIImage *image = [UIImage imageNamed:@"Navi_back"];
    
    UIButton *popButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width,image.size.height)];
    [popButton setImage:image forState:UIControlStateNormal];
    [popButton addTarget:viewController action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
    
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:popButton];

}

+(UIImage *)imageWithView:(UIView *)view
{
    view.backgroundColor= [UIColor colorWithRed:19./255 green:81./255 blue:115./255 alpha:1.0];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+(BOOL)validateIdentityCard: (NSString *)identityCard
{
    BOOL flag;
    if (identityCard.length <= 0) {
        flag = NO;
        return flag;
    }
    NSString *regex2 = @"^(\\d{14}|\\d{17})(\\d|[xX])$";
    NSPredicate *identityCardPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex2];
    return [identityCardPredicate evaluateWithObject:identityCard];
}


/**
 *  检查手机号合法性
 *
 *  @param str 手机号码
 *
 *  @return 是否合法
 */
+ (BOOL)checkTel:(NSString *)str{
    if ([str length] == 0) {
        return NO;
    }
    
    //1[0-9]{10}
    
    //^((13[0-9])|(15[^4,\\D])|(18[0,5-9]))\\d{8}$
    
    //    NSString *regex = @"[0-9]{11}";
    
    NSString *regex = @"^((13[0-9])|(147)|(15[^4,\\D])|(18[0,5-9]))\\d{8}$";
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    BOOL isMatch = [pred evaluateWithObject:str];
    
    return isMatch;
    
}

@end

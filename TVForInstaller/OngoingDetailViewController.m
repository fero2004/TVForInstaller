//
//  OngoingDetailViewController.m
//  TVForInstaller
//
//  Created by AlienLi on 15/7/16.
//  Copyright (c) 2015年 AlienLi. All rights reserved.
//

#import "OngoingDetailViewController.h"

#import "ComminUtility.h"

#import "OngoingOrder.h"

#import <ZXingObjC/ZXingObjC.h>
#import "QRCodeViewController.h"
#import "QRCodeAnimator.h"
#import "QRCodeDismissAnimator.h"

#import "NetworkingManager.h"
#import <SVProgressHUD.h>
#import "OngoingOrder.h"
#import "TotalFeeViewController.h"

typedef enum : NSUInteger {
    WECHAT,
    ALIPAY,
    CASH,
} PayType;

@interface OngoingDetailViewController ()<UITextFieldDelegate,UIViewControllerTransitioningDelegate,SubmitDelegate>

//这里是订单信息视图
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *telphoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

//输入框
@property (weak, nonatomic) IBOutlet UITextField *InstallFeeTextfield;
@property (weak, nonatomic) IBOutlet UITextField *accessoriesFeeTextfield;
@property (weak, nonatomic) IBOutlet UITextField *ServiceFeeTextfield;
@property (weak, nonatomic) IBOutlet UITextField *FlowTextfield;
//当前活跃的输入框
@property (nonatomic, strong) UITextField *activeTextfield;

//各种费用
@property (nonatomic, assign) float installCost;
@property (nonatomic, assign) float accessoryCost;
@property (nonatomic, assign) float serviceCost;
@property (nonatomic, assign) float flowCost;

//汇总费用
@property (nonatomic, assign) float totalCost;

//微信&支付宝&现金按钮
@property (weak, nonatomic) IBOutlet UIButton *wechatPay;
@property (weak, nonatomic) IBOutlet UIButton *alipay;
@property (weak, nonatomic) IBOutlet UIButton *cashPay;
//支付类型
@property (nonatomic, assign) PayType currentPayType;


//滑动视图
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) TotalFeeViewController *totalFeeVC;



@end

@implementation OngoingDetailViewController


#pragma mark - 视图生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [ComminUtility configureTitle:@"订单详情" forViewController:self];
    
    if (self.OrderInfo) {
        //如果是点击支付进行中的订单入口
        [self configOngoingOrderInfo];
    }else{
        //如果是点击正在进行中的订单入口
        [self configOrderInfo];
    }
    
    //初始化微信支付
    [self initialPayType];
    
    [self registerForKeyboardNotifications];
    
    
    //添加关闭键盘手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.view addGestureRecognizer:tap];
    
    
    
    [self.InstallFeeTextfield addTarget:self action:@selector(textfieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.accessoriesFeeTextfield addTarget:self action:@selector(textfieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.ServiceFeeTextfield addTarget:self action:@selector(textfieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.FlowTextfield addTarget:self action:@selector(textfieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
    
    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.view layoutIfNeeded];
    [self configureTextFields];

}



-(void)configureTextFields{
    self.InstallFeeTextfield.text = @"60";
    self.InstallFeeTextfield.placeholder = @"请输入金额";
    self.accessoriesFeeTextfield.text = @"120";
    self.accessoriesFeeTextfield.placeholder = @"请输入金额";

    self.installCost = 60.0;
    self.accessoryCost = 120.0;
    self.serviceCost = 0.0;
    self.flowCost = 0.0;
    [self caculateTotalCost];

}


/**
 *  支付进行中的订单
 */
-(void)configOngoingOrderInfo{
    self.nameLabel.text = self.OrderInfo[@"name"];
    self.telphoneLabel.text =  self.OrderInfo[@"phone"];
    self.addressLabel.text =  self.OrderInfo[@"home_address"];
    self.dateLabel.text = self.OrderInfo[@"order_endtime"];
    
    if ([self.OrderInfo[@"order_type"] integerValue] == 0) {
        self.typeImageView.image = [UIImage imageNamed:@"ui03_tv"];
    } else{
        self.typeImageView.image = [UIImage imageNamed:@"ui03_Broadband"];
    }
}
/**
 *  正在进行中的订单
 */
-(void)configOrderInfo{
    
    NSDictionary *order = [OngoingOrder onGoingOrder];
    
    self.nameLabel.text = order[@"name"];
    self.telphoneLabel.text =  order[@"phone"];
    self.addressLabel.text =  order[@"home_address"];
    self.dateLabel.text = order[@"order_time"];
    
    if ([order[@"order_type"] integerValue] == 0) {
        self.typeImageView.image = [UIImage imageNamed:@"ui03_tv"];
    } else{
        self.typeImageView.image = [UIImage imageNamed:@"ui03_Broadband"];
    }
    
}

-(void)dismissKeyboard:(id)sender{
    [self.InstallFeeTextfield resignFirstResponder];
    [self.accessoriesFeeTextfield resignFirstResponder];
    [self.ServiceFeeTextfield resignFirstResponder];
    [self.FlowTextfield resignFirstResponder];
}

#pragma mark - 费用输入修改
-(void)textfieldDidChanged:(UITextField *)textField{
    if (textField == self.InstallFeeTextfield) {
        self.installCost = [self.InstallFeeTextfield.text  floatValue];
    }
    if (textField == self.accessoriesFeeTextfield) {
        self.accessoryCost = [self.accessoriesFeeTextfield.text integerValue];
    }
    if (textField == self.ServiceFeeTextfield) {
        self.serviceCost = [self.ServiceFeeTextfield.text integerValue];
    }
    if (textField == self.FlowTextfield) {
        self.flowCost = [self.FlowTextfield.text integerValue];
    }
    
    //修改完成，计算费用
    [self caculateTotalCost];
}
-(void)initialPayType{
    [self.wechatPay setImage:[UIImage imageNamed:@"ui03_check_h"] forState:UIControlStateNormal];
    [self.alipay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
    [self.cashPay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
    self.currentPayType = WECHAT;
    
}
- (IBAction)clickPayType:(id)sender {
    UIButton *button = sender;
    
    if (button.tag == 0) {
        //点击微信支付
        [self initialPayType];

    } else if(button.tag == 1){
        //支付宝
        [self.wechatPay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
        [self.alipay setImage:[UIImage imageNamed:@"ui03_check_h"] forState:UIControlStateNormal];
        [self.cashPay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
        self.currentPayType = ALIPAY;

    } else{
        [self.wechatPay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
        [self.alipay setImage:[UIImage imageNamed:@"ui03_check"] forState:UIControlStateNormal];
        [self.cashPay setImage:[UIImage imageNamed:@"ui03_check_h"] forState:UIControlStateNormal];
        self.currentPayType = CASH;
    }
    
    [self caculateTotalCost];

}

-(void)caculateTotalCost{
    self.totalCost = self.installCost + self.accessoryCost + self.serviceCost + self.flowCost;
    if (self.currentPayType != CASH) {
        //如果是在线支付 减20
        self.totalCost -= 20;
        if (self.totalCost < 0.0) {
            self.totalCost = 0.0;
        }
    }
    
    //ok
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.totalFeeVC.totalFeeLabel.text = [NSString stringWithFormat:@"￥%ld",(NSInteger)self.totalCost];
    });
    
}




-(void)pop{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//点击支付
-(void)didClickSubmitButton{
    
#warning 支付处理
    if (self.currentPayType != CASH) {
        //在线支付

        [SVProgressHUD showWithStatus:@"正在生成订单"];

        NSString *pay_type = @"0";
        if (self.currentPayType == WECHAT) {
            pay_type = @"0";
        } else if (self.currentPayType == ALIPAY){
            pay_type = @"1";
        } else{
            pay_type = @"2";
        }
        [NetworkingManager BeginPayForUID:self.OrderInfo[@"uid"] byEngineerID:self.OrderInfo[@"engineer_id"] totalFee:[NSString stringWithFormat:@"%.2f",self.totalCost] pay_type:pay_type WithcompletionHandler:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject[@"success"] integerValue] == 1) {
                NSString *url = responseObject[@"obj"];
                NSError *error = nil;
                CGImageRef qrImage = nil;
                ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
                ZXBitMatrix* result = [writer encode:url
                                              format:kBarcodeFormatQRCode
                                               width:500
                                              height:500
                                               error:&error];
                if (result) {

                    qrImage = [[ZXImage imageWithMatrix:result] cgimage];

                    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
                    QRCodeViewController *qrcodeVC = [sb instantiateViewControllerWithIdentifier:@"QRCodeViewController"];
                    qrcodeVC.transitioningDelegate = self;
                    qrcodeVC.image = [UIImage imageWithCGImage:qrImage];
                    qrcodeVC.modalTransitionStyle = UIModalPresentationOverCurrentContext;
                    [self showDetailViewController:qrcodeVC sender:self];
                    NSDictionary *order = [OngoingOrder onGoingOrder];

                    [NetworkingManager ModifyOrderStateByID:order[@"uid"] latitude:[order[@"location"][1] doubleValue] longitude:[order[@"location"][0] doubleValue] order_state:@"3" WithcompletionHandler:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if ([responseObject[@"status"] integerValue] == 0) {
                            //修改订单为完成未支付

                            [OngoingOrder setExistOngoingOrder:NO];
                            [OngoingOrder setOrder:nil];


                        }
                    } failHandler:^(AFHTTPRequestOperation *operation, NSError *error) {

                    }];

                } else {

                }
                [SVProgressHUD dismiss];

                
            } else{
                [SVProgressHUD showErrorWithStatus:@"出错啦"];
            }

        } failHandler:^(AFHTTPRequestOperation *operation, NSError *error) {
        }];
    }
}
//- (IBAction)clickCreatePayOrder:(id)sender {

    
//    if ([self.moneyTextField.text isEqualToString:@""]) {
//        
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"支付金额不可为空" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            
//        }];
//        [alert addAction:action];
//        
//        [self presentViewController:alert animated:YES completion:nil];
//    }else {
//        NSDictionary *info = [OngoingOrder onGoingOrder];
//        
//        NSString *pay_type = @"0";
//        if (_iswechatPay) {
//            pay_type = @"0";
//        } else{
//            pay_type = @"1";
//        }
//        JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
//        hud.textLabel.text = @"正在生成订单";
//        [hud showInView:self.view];
//        
//        
//        [NetworkingManager BeginPayForUID:info[@"uid"] byEngineerID:info[@"engineer_id"] totalFee:self.moneyTextField.text pay_type:pay_type WithcompletionHandler:^(AFHTTPRequestOperation *operation, id responseObject) {
//            if ([responseObject[@"success"] integerValue] == 1) {
//                NSString *url = responseObject[@"obj"];
//                NSError *error = nil;
//                CGImageRef qrImage = nil;
//                ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
//                ZXBitMatrix* result = [writer encode:url
//                                              format:kBarcodeFormatQRCode
//                                               width:500
//                                              height:500
//                                               error:&error];
//                if (result) {
//                    
//                    qrImage = [[ZXImage imageWithMatrix:result] cgimage];
//                    
//                    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
//                    QRCodeViewController *qrcodeVC = [sb instantiateViewControllerWithIdentifier:@"QRCodeViewController"];
//                    qrcodeVC.transitioningDelegate = self;
//                    qrcodeVC.image = [UIImage imageWithCGImage:qrImage];
//                    qrcodeVC.modalTransitionStyle = UIModalPresentationOverCurrentContext;
//                    [self showDetailViewController:qrcodeVC sender:self];
//                    NSDictionary *order = [OngoingOrder onGoingOrder];
//
//                    [NetworkingManager ModifyOrderStateByID:order[@"uid"] latitude:[order[@"location"][1] doubleValue] longitude:[order[@"location"][0] doubleValue] order_state:@"3" WithcompletionHandler:^(AFHTTPRequestOperation *operation, id responseObject) {
//                        if ([responseObject[@"status"] integerValue] == 0) {
//                            //修改订单为完成未支付
//                            
//                            [OngoingOrder setExistOngoingOrder:NO];
//                            [OngoingOrder setOrder:nil];
//                            
//                            
//                        }
//                    } failHandler:^(AFHTTPRequestOperation *operation, NSError *error) {
//                        
//                    }];
//                    
//                } else {
//                    
////                    NSString *errorMessage = [error localizedDescription];
//                }
//                
//                
//            }
//            [hud dismissAfterDelay:1.0];
//
//        } failHandler:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [hud dismissAfterDelay:1.0];
//        }];
//
//    }
//}


//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//    if ([segue.identifier isEqualToString:@"QRCodeSegue"]) {
//        
//        
//        NSDictionary *info = [OngoingOrder onGoingOrder];
//        
//        NSString *pay_type = @"0";
//        if (_iswechatPay) {
//            pay_type = @"0";
//        } else{
//            pay_type = @"1";
//        }
//        
//        [NetworkingManager BeginPayForUID:info[@"uid"] byEngineerID:info[@"engineer_id"] totalFee:self.moneyTextField.text pay_type:pay_type WithcompletionHandler:^(AFHTTPRequestOperation *operation, id responseObject) {
//            if ([responseObject[@"success"] integerValue] == 1) {
//                NSString *url = responseObject[@"obj"];
//                NSError *error = nil;
//                CGImageRef qrImage = nil;
//                ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
//                ZXBitMatrix* result = [writer encode:url
//                                              format:kBarcodeFormatQRCode
//                                               width:500
//                                              height:500
//                                               error:&error];
//                if (result) {
//                    
//                    qrImage = [[ZXImage imageWithMatrix:result] cgimage];
//                    
//                    QRCodeViewController *qrcodeVC = segue.destinationViewController;
//                    qrcodeVC.transitioningDelegate = self;
//                    qrcodeVC.image = [UIImage imageWithCGImage:qrImage];
//                    qrcodeVC.modalTransitionStyle = UIModalPresentationOverCurrentContext;
//                } else {
//                    
//                    NSString *errorMessage = [error localizedDescription];
//                }
//
//                
//            }
//        } failHandler:^(AFHTTPRequestOperation *operation, NSError *error) {
//            
//        }];
//
//    }
//}


#pragma mark -keyboard deal
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShown:(NSNotification*)aNotification
{
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextfield.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeTextfield.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextfield = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextfield = nil;
}

#pragma mark -segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"TotalFeeSegue"]) {
        //
        self.totalFeeVC = (TotalFeeViewController*)segue.destinationViewController;
    }
}


#pragma mark - ViewController Transition Delegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [[QRCodeAnimator alloc] init];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [[QRCodeDismissAnimator alloc] init];

}




@end

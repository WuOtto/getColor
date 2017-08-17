//
//  ViewController.m
//  GetColor
//
//  Created by otto on 2017/8/17.
//  Copyright © 2017年 otto. All rights reserved.
//

#import "ViewController.h"
#import "GetColorViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)goToGetColor:(UIButton *)sender {
    GetColorViewController *getColorVC = [[GetColorViewController alloc] init];
    [self presentViewController:getColorVC animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

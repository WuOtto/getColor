//
//  GetColorViewController.m
//  GetColor
//
//  Created by otto on 2017/8/17.
//  Copyright © 2017年 otto. All rights reserved.
//

#import "GetColorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "UIView+ColorOfPoint.h"
#import "UIColor+Extension.h"

#define MyWidth [UIScreen mainScreen].bounds.size.width
#define MyHeight [UIScreen mainScreen].bounds.size.height

#define colorViewWidth 20 //取色框宽度

@interface GetColorViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *preview;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UILabel *colorLabel;

//硬件设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入流
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//协调输入输出流的数据
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;  //用于捕捉静态图片
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;    //原始视频帧，用于获取实时图像以及视频录制

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) CGFloat accelerometerDataX;
@property (nonatomic, assign) CGFloat accelerometerDataY;
@property (nonatomic, assign) CGFloat accelerometerDataZ;

@end

@implementation GetColorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake((MyWidth - colorViewWidth)/2, (MyHeight - 128 - colorViewWidth)/2, colorViewWidth, colorViewWidth)];
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[UIColor yellowColor] CGColor];
    
    view.layer.cornerRadius = colorViewWidth/2;
    view.layer.masksToBounds = YES;
    
    view.backgroundColor = [UIColor clearColor];
    [self.preview addSubview:view];
    
    if ([self authCamera]) {
        [self setupCamera];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupMotionManager];
            
        });
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)authCamera{
    __block BOOL auth = YES;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                //*******************先回主线程
                if (granted) {
                    //第一次用户接受
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //用户拒绝
                        
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"您已阻止APP访问你的相机，请前往设置-隐私-相机中打开" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"知道啦" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self performSelector:@selector(back:) withObject:nil afterDelay:1.0];
                        }];
                        [alertController addAction:sureAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    });
                    auth = NO;
                }
            }];
        }
            break;
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
        }
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:{
            // 用户明确地拒绝授权，或者相机设备无法访问
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"您已阻止APP访问你的相机，请前往设置-隐私-相机中打开" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"知道啦" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self performSelector:@selector(back:) withObject:nil afterDelay:1.0];
            }];
            [alertController addAction:sureAction];
            [self presentViewController:alertController animated:YES completion:nil];
            auth = NO;
        }
            break;
        default:
            break;
    }
    {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] || [mediaTypes count] <= 0)
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"相机不可用" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"知道啦" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self performSelector:@selector(back:) withObject:nil afterDelay:1.0];
            }];
            [alertController addAction:sureAction];
            [self presentViewController:alertController animated:YES completion:nil];
            auth = NO;
        }
        else
        {
            
        }
    }
    return auth;
}

- (void)setupCamera{
    
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}


- (void)setupMotionManager{
    self.accelerometerDataX = 0;
    self.accelerometerDataY = 0;
    self.accelerometerDataZ = 0;
    
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setAccelerometerUpdateInterval:1.0/30.0];
    __weak typeof(self) weakSelf = self;
    if (!self.motionManager.accelerometerAvailable) {
        NSLog(@"The accelerometer is unavailable");
        return;
    }
    __block int i = 0;
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (error) {
            NSLog(@"CoreMotion Error : %@",error);
            [weakSelf.motionManager stopAccelerometerUpdates];
        }
        if (i == 0) {
            //weakSelf.accelerometerDataX = accelerometerData.acceleration.x;
            //weakSelf.accelerometerDataY = accelerometerData.acceleration.y;
            //weakSelf.accelerometerDataZ = accelerometerData.acceleration.z;
        }
        i++;
        if(fabs(weakSelf.accelerometerDataY - accelerometerData.acceleration.y) > .1 || fabs(weakSelf.accelerometerDataX - accelerometerData.acceleration.x) > .1 || fabs(weakSelf.accelerometerDataZ - accelerometerData.acceleration.z) > .1){
            [weakSelf dynamicRefresh];
            weakSelf.accelerometerDataX = accelerometerData.acceleration.x;
            weakSelf.accelerometerDataY = accelerometerData.acceleration.y;
            weakSelf.accelerometerDataZ = accelerometerData.acceleration.z;
        }
    }];
}

- (void)dynamicRefresh{
    if (self.session && ![self.session isRunning]) {
        return;
    }
    static BOOL flag = YES;
    if (flag) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            flag = YES;
        });
        flag = NO;
        [self ReFreshColor];
    }
}

- (void)ReFreshColor{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
        CGPoint tmpPoint =CGPointMake((MyWidth - colorViewWidth)/2 + colorViewWidth/2, (MyHeight - 128 - colorViewWidth)/2 + colorViewWidth/2);
        UIColor *pointColor = [weakSelf.preview colorOfPoint:tmpPoint];
        
        NSLog(@"color---%@",[UIColor toStrByUIColor:pointColor]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.colorLabel.text = [UIColor toStrByUIColor:pointColor];
            self.colorView.backgroundColor = pointColor;
            
        });
        
        
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //设置图像方向，否则largeImage取出来是反的
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    UIImage *currentPreview = [self imageFromSampleBuffer:sampleBuffer];
    [self.preview setImage:currentPreview];
}

//CMSampleBufferRef转NSImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

#pragma mark - getter
-(AVCaptureDevice *)device{
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([_device lockForConfiguration:nil]) {
            //自动闪光灯
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
            //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            //自动对焦
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            //自动曝光
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [_device unlockForConfiguration];
        }
    }
    return _device;
}

-(AVCaptureDeviceInput *)input{
    if (_input == nil) {
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    }
    return _input;
}

-(AVCaptureStillImageOutput *)stillImageOutput{
    if (_stillImageOutput == nil) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    return _stillImageOutput;
}

-(AVCaptureVideoDataOutput *)videoDataOutput{
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        //设置像素格式，否则CMSampleBufferRef转换NSImage的时候CGContextRef初始化会出问题
        //因为捕捉到得帧是YUV颜色通道的，这种颜色通道无法通过以上函数转换，RGBA颜色通道才可以成功转换，所以，先需要把视频帧的输出格式设置一下
        [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    return _videoDataOutput;
}

-(AVCaptureSession *)session{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.stillImageOutput]) {
            [_session addOutput:self.stillImageOutput];
        }
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
        }
    }
    return _session;
}


- (IBAction)back:(UIButton *)sender {
    if (self.session) {
        [self.session stopRunning];
    }
    [self.motionManager stopAccelerometerUpdates];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

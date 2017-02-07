//
//  ViewController.m
//  WKWebViewtest
//
//  Created by mac on 17/2/6.
//  Copyright © 2017年 qzlp. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WKWebView.h>
#import <WebKit/WebKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>


@interface ViewController ()<WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) WKWebView *webview;

@property (nonatomic, strong) UIProgressView *progressview;

@property (nonatomic, strong) UIButton *lastbutton;

@property (nonatomic, strong) UIButton *nextbutton;

@property (nonatomic, strong) UIButton *refreshbutton;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@end

@implementation ViewController

- (WKWebView *)webview {
    if (!_webview) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKWebView *webview = [[WKWebView alloc] initWithFrame:(CGRect){0, 60, self.view.bounds.size.width, self.view.bounds.size.height - 60} configuration:config];
        webview.UIDelegate = self;
        webview.navigationDelegate = self;
        
        [webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        self.webview = webview;
        [self.view addSubview:_webview];
    }
    return _webview;
}

- (UIProgressView *)progressview {
    if (!_progressview) {
        self.progressview = [[UIProgressView alloc] initWithFrame:(CGRect){0, 60, self.view.bounds.size.width, 2}];
        [_progressview setProgressViewStyle:UIProgressViewStyleDefault]; //设置进度条类型
        [self.view addSubview:_progressview];
    }
    return _progressview;
}

- (UIButton *)lastbutton {
    if (!_lastbutton) {
        self.lastbutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lastbutton setTitle:@"后退" forState:UIControlStateNormal];
        _lastbutton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_lastbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_lastbutton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        _lastbutton.frame = CGRectMake(15, 20, 40, 40);
        [_lastbutton addTarget:self action:@selector(handlelastbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_lastbutton];
    }
    return _lastbutton;
}

- (UIButton *)nextbutton {
    if (!_nextbutton) {
        self.nextbutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextbutton setTitle:@"前进" forState:UIControlStateNormal];
        [_nextbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_nextbutton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        _nextbutton.titleLabel.font = [UIFont systemFontOfSize:12];
        _nextbutton.frame = CGRectMake(80, 20, 40, 40);
        [_nextbutton addTarget:self action:@selector(handlenextbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_nextbutton];
    }
    return _nextbutton;
}

- (UIButton *)refreshbutton {
    if (!_refreshbutton) {
        self.refreshbutton = [UIButton buttonWithType:UIButtonTypeCustom];
        _refreshbutton.frame = CGRectMake(self.view.bounds.size.width - 15 -40, 20, 40, 40);
        _refreshbutton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_refreshbutton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_refreshbutton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [_refreshbutton setTitle:@"刷新" forState:UIControlStateNormal];
        [_refreshbutton addTarget:self action:@selector(handlerefreshbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_refreshbutton];
    }
    return _refreshbutton;
}

- (void)handlelastbuttonaction:(UIButton *)sender {
    [self.webview goBack];
}

- (void)handlenextbuttonaction:(UIButton *)sender {
    [self.webview goForward];
}

- (void)handlerefreshbuttonaction:(UIButton *)sender {
    [self.webview reload];
}

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (void)dealloc {
    [self.webview removeObserver:self forKeyPath:@"estimatedProgress"];
    WKUserContentController *userCC =
    self.webview.configuration.userContentController;
    [userCC removeScriptMessageHandlerForName:@"nextpage"];
    [userCC removeScriptMessageHandlerForName:@"telphone"];
    [userCC removeScriptMessageHandlerForName:@"makephoto"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /* NSString *urlstr = @"http://www.jianshu.com";
     NSURL *url = [NSURL URLWithString:urlstr];
     NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
     
     [self.webview loadRequest:request];
     */
    
    //为JS调用OC添加脚本
    WKUserContentController *userCC =
    self.webview.configuration.userContentController;
    //JS调用OC 添加处理脚本
    [userCC addScriptMessageHandler:self name:@"nextpage"];
    [userCC addScriptMessageHandler:self name:@"telphone"];
    [userCC addScriptMessageHandler:self name:@"makephoto"];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"JS" ofType:@"html"];
    NSURL *baseURL = [[NSBundle mainBundle] bundleURL];
    [self.webview loadHTMLString:[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] baseURL:baseURL];
    self.lastbutton.enabled = [self.webview canGoBack];
    self.nextbutton.enabled = [self.webview canGoForward];
    
    
    //OC调用JS的view
    CGFloat width = (self.view.bounds.size.width - 15 * 4)/3;
    UIView *bottomview = [[UIView alloc] initWithFrame:(CGRect){0, self.view.bounds.size.height - 200, self.view.bounds.size.width, 200}];
    bottomview.backgroundColor = [UIColor colorWithRed:0 green:191.0/255 blue:1 alpha:1];
    UILabel *tipslanbel = [[UILabel alloc] initWithFrame:(CGRect){0,10, self.view.bounds.size.width, 40}];
    tipslanbel.text = @"这是OC原生按钮控件";
    tipslanbel.textAlignment = NSTextAlignmentCenter;
    [bottomview addSubview:tipslanbel];
    
    UIButton *elertbu = [UIButton buttonWithType:UIButtonTypeCustom];
    elertbu.frame = CGRectMake(15, 30 +CGRectGetMaxY(tipslanbel.frame), width, 80);
    elertbu.backgroundColor = [UIColor redColor];
    [elertbu addTarget:self action:@selector(handleelertbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
    [elertbu setTitle:@"1" forState:UIControlStateNormal];
    [bottomview addSubview:elertbu];
    UIButton *confirmbu = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmbu.frame = CGRectMake(15 + CGRectGetMaxX(elertbu.frame), 30 + CGRectGetMaxY(tipslanbel.frame), width, 80);
    confirmbu.backgroundColor = [UIColor redColor];
    [confirmbu addTarget:self action:@selector(handleelertbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
    [confirmbu setTitle:@"2" forState:UIControlStateNormal];
    [bottomview addSubview:confirmbu];
    UIButton *promptbu = [UIButton buttonWithType:UIButtonTypeCustom];
    promptbu.frame = CGRectMake(15 + CGRectGetMaxX(confirmbu.frame), 30 + CGRectGetMaxY(tipslanbel.frame), width, 80);
    promptbu.backgroundColor = [UIColor redColor];
    [promptbu addTarget:self action:@selector(handleelertbuttonaction:) forControlEvents:UIControlEventTouchUpInside];
    [promptbu setTitle:@"3" forState:UIControlStateNormal];
    [bottomview addSubview:promptbu];
    [self.view addSubview:bottomview];
}

- (void)handleelertbuttonaction:(UIButton *)sender {
    NSString *jsmethodstr = nil;
    switch ([sender.titleLabel.text intValue]) {
        case 1:
            jsmethodstr = @"altrtmethod()";
            break;
            
        case 2:
            jsmethodstr = @"confirmmethod()";
            break;
            
        case 3:
            jsmethodstr = @"promotmethod()";
            break;
        default:
            break;
    }
    [self.webview evaluateJavaScript:jsmethodstr completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        //TODO
        NSLog(@"%@ %@",response,error);
    }];
    
}



// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.progressview.hidden = NO;
    self.refreshbutton.enabled = NO;
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    //页面开始返回时调用
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //页面加载完成时调用
    self.progressview.hidden = YES;
    self.progressview.progress = 0;
    self.lastbutton.enabled = [self.webview canGoBack];
    self.nextbutton.enabled = [self.webview canGoForward];
    self.refreshbutton.enabled = YES;
}

//接收到服务器求之后跳转
//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
//
//}

//在收到请求后，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
//
//}

//在发送请求之前，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
//
//}

//创建一个新的webview
//- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
//    return nil;
//}

//界面弹出警告框   在JS端调用alert函数时，会触发此代理方法
// JS端调用alert时所传的数据可以通过message拿到
// 在原生得到结果后，需要回调JS，是通过completionHandler回调
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@"%@", message);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

//界面弹出确认框   JS端调用confirm函数时，会触发此方法
// 通过message可以拿到JS端所传的数据
// 在iOS端显示原生alert得到YES/NO后
// 通过completionHandler回调给JS端
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    NSLog(@"%@", message);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:@"这是OC调用JS的confirm方法" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
    
}

//界面弹出输入框   JS端调用prompt函数时，会触发此方法
// 要求输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    NSLog(@"%@", prompt);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:prompt message:@"请输你的名字" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
    
}

//从web界面中接受一个脚本时调用
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    NSLog(@"%@",message.body);
    
    if ([message.name isEqualToString:@"nextpage"]) {
        NSString *urlstr = @"http://www.baidu.com";
        NSURL *url = [NSURL URLWithString:urlstr];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        
        [self.webview loadRequest:request];
        
    }
    if ([message.name isEqualToString:@"telphone"]) {
        NSString *str=[[NSString alloc] initWithFormat:@"tel:%@",message.body];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];    }
    if ([message.name isEqualToString:@"makephoto"]) {
        UIAlertController *sheetconcon = [UIAlertController alertControllerWithTitle:@"图片来源" message:@"从拍照或相册获取" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            //录制视频时长，默认10s
            self.imagePickerController.videoMaximumDuration = 15;
            
            //相机类型（拍照、录像...）字符串需要做相应的类型转换
            self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage];
            
            //视频上传质量
            //UIImagePickerControllerQualityTypeHigh高清
            //UIImagePickerControllerQualityTypeMedium中等质量
            //UIImagePickerControllerQualityTypeLow低质量
            //UIImagePickerControllerQualityType640x480
            self.imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
            
            //设置摄像头模式（拍照，录制视频）为录像模式
            self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
            
        }];
        UIAlertAction *archiveAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
        }];
        [sheetconcon addAction:cancelAction];
        [sheetconcon addAction:deleteAction];
        [sheetconcon addAction:archiveAction];
        [self presentViewController:sheetconcon animated:YES completion:nil];
    }
}

#pragma mark - UIsheetdelegate


//KVO监测方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        [self.progressview setProgress:self.webview.estimatedProgress animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

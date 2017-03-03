//
//  ViewController.m
//  OC与JS交互之UIWebView
//
//  Created by user on 16/8/15.
//  Copyright © 2016年 rrcc. All rights reserved.
//

#import "ViewController.h"
#import <CoreFoundation/CFURL.h>

static NSString *ClentPrefix = @"wx://pandareader/";

@interface ViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *baseURL = [[NSBundle mainBundle] bundleURL];
    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] baseURL:baseURL];
    
    //        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://qa.megatron.baidu-shucheng.com:8091/recommend?p1=appstore&p2=appstore&p3=c94be2da676c4e80bdcddcebb5b1b4a55bf233a5&p4=Apple&p5=Apple&p6=iPhone&p7=ios&p8=10.2&p9=wifi&p10=7.2.0&p11=1242&p12=2208&p13=14384827&p14=720&p15=10008&p16=a15775c58f1f28f4eaeca8ba271e16e2&p17=28EC0A6D-1B2F-43C1-8354-8DBAA3D8F488&p18=appstore"]]];
}


- (void)showMsg:(NSString *)msg {
    [[[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (IBAction)btnClick:(UIButton *)sender {
    //网页加载完成之后调用JS代码才会执行，因为这个时候html页面已经注入到webView中并且可以响应到对应方法
    if (sender.tag == 123) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"alertMobile()"];
    }
    
    if (sender.tag == 234) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"alertName('小红')"];
    }
    
    if (sender.tag == 345) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"alertSendMsg('18870707070','周末爬山真是件愉快的事情')"];
    }
    
}

#pragma mark - JS调用OC方法列表
- (void)showMobile {
    [self showMsg:@"我是下面的小红 手机号是:18870707070"];
}

- (void)showName:(NSString *)name {
    NSString *info = [NSString stringWithFormat:@"你好 %@, 很高兴见到你",name];
    
    [self showMsg:info];
}

- (void)showSendNumber:(NSString *)num msg:(NSString *)msg {
    NSString *info = [NSString stringWithFormat:@"这是我的手机号: %@, %@ !!",num,msg];
    
    [self showMsg:info];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    //OC调用JS是基于协议拦截实现的 下面是相关操作
    NSString *backUrl = [[request URL] absoluteString];
    NSString *relativePath = request.mainDocumentURL.relativePath;
    
    NSLog(@"WBS relativePath is  ++++ %@ ++++   backUrl is ===== %@ =====",relativePath,backUrl);
    // 实际应用中使用 backUrl 进行JSON解析操作
    /*{
     在实际使用中，可以和后端商量好这个地址前缀（交互协议）比如如下
     }*/
    NSString *scheme = @"rrcc://";
    
    if ([backUrl hasPrefix:scheme]) {
        NSString *subPath = [backUrl substringFromIndex:scheme.length];
        
        if ([subPath containsString:@"?"]) {//1个或多个参数
            
            if ([subPath containsString:@"&"]) {//多个参数
                NSArray *components = [subPath componentsSeparatedByString:@"?"];
                
                NSString *methodName = [components firstObject];
                
                methodName = [methodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
                SEL sel = NSSelectorFromString(methodName);
                
                NSString *parameter = [components lastObject];
                NSArray *params = [parameter componentsSeparatedByString:@"&"];
                
                if (params.count == 2) {
                    if ([self respondsToSelector:sel]) {
                        [self performSelector:sel withObject:[params firstObject] withObject:[params lastObject]];
                    }
                }
                
                
            } else {//1个参数
                NSArray *components = [subPath componentsSeparatedByString:@"?"];
                
                NSString *methodName = [components firstObject];
                methodName = [methodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
                SEL sel = NSSelectorFromString(methodName);
                
                NSString *parameter = [components lastObject];
                
                if ([self respondsToSelector:sel]) {
                    [self performSelector:sel withObject:parameter];
                }
                
            }
            
        } else {//没有参数
            NSString *methodName = [subPath stringByReplacingOccurrencesOfString:@"_" withString:@":"];
            SEL sel = NSSelectorFromString(methodName);
            
            if ([self respondsToSelector:sel]) {
                [self performSelector:sel];
            }
        }
    }
    
    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

 /********************* 完整的JS 调用OC 示例 使用baidu-shucheng.com的URl测试 *************************/

///// 第一步： 拦截请求 获取协议字符串儿
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSLog(@"%@",NSStringFromSelector(_cmd));
//    BOOL  isGo = YES;  // 是否允许加载（决定是否拦截）
//    //OC调用JS是基于协议拦截实现的 下面是相关操作
//    NSString *backUrl = [[request URL] absoluteString];
//    if([backUrl hasPrefix:ClentPrefix])
//    {
//        NSRange range = {0};
//        range.location = [ClentPrefix length];
//        range.length = [backUrl length] - range.location;
//        NSString* json = [backUrl substringWithRange:range];
//        
//        NSString* newjson = (NSString*) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,(CFStringRef) json,CFSTR(""),kCFStringEncodingUTF8));
//      
//        [self WebviewClientExecSync:newjson];
//        
//        isGo = NO;
//    }else{
//        isGo = YES;
//    }
//    return isGo;
//}
//
//// 第三步，==== 解析JSON数据
////当webview接到了js交互消息的时候，会回调给这里
////json格式基本都是 {"apiName":"xxx", "params":{xxxxx}}
//-(void*)WebviewClientExecSync:(NSString*) json
//{
//    NSData *string = [json dataUsingEncoding:NSUTF8StringEncoding];
//    NSError *error = nil;
//    id rootData = [NSJSONSerialization JSONObjectWithData:string options:NSJSONReadingMutableLeaves error:&error];
//    if (rootData) {
//        if ([rootData isKindOfClass:[NSDictionary class]]) {
//            [self webViewClientCallBackEventHandle:rootData];
//        } else if ([rootData isKindOfClass:[NSArray class]]) {
//            for (NSDictionary *data in rootData) {
//                [self webViewClientCallBackEventHandle:data];
//            }
//        }
//    }
//}
//
//
//// 第三步，==== 执行操作 传递数据
//- (void)webViewClientCallBackEventHandle:(NSDictionary *)rootData
//{
//    NSString* apiName = [rootData objectForKey:@"apiName"];
//    
//    if ([apiName isEqualToString:@"openSysApp"])
//    {
//        // 调起其他App（授权登录）
//    }
//    else if([apiName isEqualToString:@"view_to"])
//    {
//     // 跳转控制器
//    }
//    else if([apiName isEqualToString:@"link_to"])
//    {
//     /// 链接到新的URl （webview加载） 传递url
//    }
//    else if ([apiName isEqualToString:@"native_call"])
//    {
//        // 本地调起界面
//    }
//    else if ([apiName isEqualToString:@"book_down"])
//    {
//        /// 下载图书 需要传递 bookid
//    }
//    else if ([apiName isEqualToString:@"goback"])
//    {
//        /// pop 当前控制器
//    }
//}

@end



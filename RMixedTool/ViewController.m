//
//  ViewController.m
//  RMixedTool
//
//  Created by ron on 2021/6/22.
//

#import "ViewController.h"
#import "RMProjectParser.h"
#import "RMSourceScanner.h"
#import "RMProjectManager.h"
#import <objc/runtime.h>
@interface ViewController()

@property (weak) IBOutlet NSTextField *txtProjectPath;
@property (weak) IBOutlet NSTextField *txtMixConfigPath;
@property (weak) IBOutlet NSTextField *lbInfo;
@property (weak) IBOutlet NSView *viewTargets;
@property (weak) IBOutlet NSDictionary *dicSelectTarget;
@property (weak) IBOutlet NSTextField *txtExcudePath;

@end
@implementation ViewController

- (IBAction)btnStartMix:(id)sender {
    [[RMProjectManager shareManager] beginMixed];
    [self alertMessage:@"混淆结束"];
}
- (IBAction)btnRecover:(id)sender {
}


-(void)alertMessage:(NSString *)str{
    NSAlert *alert =  [[NSAlert alloc] init];
    alert.messageText = str;
    [alert runModal];
}
- (IBAction)btnGenealMixConfig:(id)sender {
    if(_dicSelectTarget==nil){
        [self alertMessage:@"请先选择一个target"];
        return;
    }
    NSDictionary *dic =  [[RMProjectManager shareManager] generalOrUpdateMixConfigFile:self.txtMixConfigPath.stringValue target:[_dicSelectTarget objectForKey:@"name"]];
    if(dic){
        [self alertMessage:@"成功"];
    }else{
        [self alertMessage:@"生成失败"];
    }
}

-(void)selectTarget:(id)sender{
    NSDictionary *dic = objc_getAssociatedObject(sender, "obj");
    if(dic){
        self.dicSelectTarget = dic;
      
    }
}
- (IBAction)btnStartAnalyse:(id)sender {
    if(_txtExcudePath.stringValue.length>0){
        if([[NSFileManager defaultManager] fileExistsAtPath:_txtExcudePath.stringValue]){
            NSString *content = [NSString stringWithContentsOfFile:_txtExcudePath.stringValue encoding:NSUTF8StringEncoding error:nil];
            if(content.length>0){
                NSArray *ar = [content componentsSeparatedByString:@"\n"];
                NSMutableArray *arrayTrim = [NSMutableArray array];
                for (NSString *s in ar) {
                    [arrayTrim addObject:[s stringByReplacingOccurrencesOfString:@" " withString:@""]];
                }
                if(arrayTrim.count>0){
                    [[RMProjectManager shareManager] addExcueWords:arrayTrim];
                }
            }
        }
        
    }
    
    [[RMProjectManager shareManager] config:self.txtProjectPath.stringValue];
    
    [[RMProjectManager shareManager] startAnalyse:^(NSError * _Nonnull error, NSArray * _Nonnull targets) {
        
        NSString *msg = [[error userInfo] objectForKey:@"msg"];
        [self.lbInfo setStringValue:msg];
        if(error == nil||error.code == 0){
            
            for(int i =0;i<targets.count;i++){
                NSDictionary *dic = [targets objectAtIndex:i];
                CGRect f  = CGRectMake(160*i, self.viewTargets.frame.size.height-60, 160, 30);
                NSButton *btn = [NSButton radioButtonWithTitle:[dic objectForKey:@"name"] target:self action:@selector(selectTarget:)];
                btn.frame = f;
                objc_setAssociatedObject(btn, "obj", dic, OBJC_ASSOCIATION_RETAIN);
                
                [self.viewTargets addSubview:btn];
                
            }
        }else{
            [self alertMessage:msg];
        }
    }];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear{
    [super viewDidAppear];
    if([NSApplication sharedApplication].windows.count>0){
        NSWindow *w = [[NSApplication sharedApplication].windows objectAtIndex:0];
        w.title = [NSString stringWithFormat:@"iOS混淆工具 Version:%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]] ;
    }
    
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end

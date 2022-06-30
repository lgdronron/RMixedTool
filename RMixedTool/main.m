//
//  main.m
//  RMixedTool
//
//  Created by ron on 2021/6/22.
//

#import <Cocoa/Cocoa.h>
#import "RMProjectManager.h"

NSString * in_path_project = nil;
NSString * in_target_name = nil;
NSString * in_file_exclude = nil;
NSString * in_file_mixjson = nil;
NSString * path_project_des = nil;

void exitApp(NSString* error){
    NSLog(error);
    exit(0);
}

bool prepare(){
    NSLog(@"开始分析。。。。");
    
    if([[NSFileManager defaultManager] fileExistsAtPath:in_file_exclude]){
        NSString *content = [NSString stringWithContentsOfFile:in_file_exclude encoding:NSUTF8StringEncoding error:nil];
        if(content.length>0){
            NSArray *ar = [content componentsSeparatedByString:@"\n"];
            NSMutableArray *arrayTrim = [NSMutableArray array];
            for (NSString *s in ar) {
                [arrayTrim addObject:[s stringByReplacingOccurrencesOfString:@" " withString:@""]];
            }
            if(arrayTrim.count>0){
                [[RMProjectManager shareManager] addExcueWords:arrayTrim];
            }
            
            NSString *destDir = [NSString stringWithFormat:@"%@/%@_mixed",NSHomeDirectory(),in_target_name];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:destDir error:&error];
            if (error && error.code != 4){
                exitApp(@"删除旧的混淆目录失败，退出");
            }
            error = nil;
            
            [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:destDir] withIntermediateDirectories:true attributes:nil error:&error];
            path_project_des = [destDir stringByAppendingFormat:@"/%@",in_target_name];
            [[NSFileManager defaultManager] copyItemAtPath:in_path_project toPath:path_project_des error:&error];
            if (error){
                exitApp(error.description);
            }
            
           
        }
    }else{
        exitApp(@"排除文件不存在，退出");
        
    }
    return  true;
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        NSLog(@"输入参数：\n");
        for(int i = 0;i<argc;i++){
            NSLog(@"%s",argv[i]);
        }
        
        
        if (argc >= 5){
            in_path_project = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
            in_target_name = [[NSString alloc] initWithCString:argv[2] encoding:NSUTF8StringEncoding];
            in_file_exclude = [[NSString alloc] initWithCString:argv[3] encoding:NSUTF8StringEncoding];
            in_file_mixjson = [[NSString alloc] initWithCString:argv[4] encoding:NSUTF8StringEncoding];
            
            if( prepare()){
                if(in_file_exclude.length>0){
                    if([[NSFileManager defaultManager] fileExistsAtPath:in_file_exclude]){
                        NSString *content = [NSString stringWithContentsOfFile:in_file_exclude encoding:NSUTF8StringEncoding error:nil];
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
                
                [[RMProjectManager shareManager] config:path_project_des];
                
                [[RMProjectManager shareManager] startAnalyse:^(NSError * _Nonnull error, NSArray * _Nonnull targets) {
                    NSDictionary *dicTarget = nil;
                    for (NSDictionary *dic in targets){
                        if ([[dic objectForKey:@"name"] isEqualToString:in_target_name]){
                            dicTarget = dic;
                            break;
                        }
                    }
                    if (dicTarget) {
                        NSLog(@"找到对应的target，开始扫描生产映射文件");
                        NSDictionary *dic =  [[RMProjectManager shareManager] generalOrUpdateMixConfigFile:in_file_mixjson target:in_target_name];
                        if(dic){
                            NSLog(@"生成成功，开始混淆");
                            [[RMProjectManager shareManager] beginMixed];
                            NSLog(@"混淆结束");
                        }else{
                            exitApp(@"General Failed!");
                        }
                        
                    }else{
                        exitApp(@"找不到对应的target");
                    }
                }];
            }else{
                exitApp(@"部署失败，推出");
            }
            
        }
        
    }
    return NSApplicationMain(argc, argv);
}

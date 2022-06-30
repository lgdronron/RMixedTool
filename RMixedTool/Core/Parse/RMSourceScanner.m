//
//  RMSourceScanner.m
//  RMixedTool
//
//  Created by ron on 2021/6/24.
//

#import "RMSourceScanner.h"
#import "RMWordManager.h"

@interface RMSourceScanner(){
    BOOL _isGeneralNewWord;
}

@end

@implementation RMSourceScanner

-(RMSourceScanner *)initWithPath:(NSString *)filePath{
    if(self = [super init]){
       
        self.strFilePath = filePath;
        self.arrayOfPropertys = [NSMutableArray array];
        self.arrayOfClassName = [NSMutableArray array];
        self.arrayOfMethods = [NSMutableArray array];
    }
    return self;;
}
-(NSString *)trimString:(NSString *)str{
    str = [str stringByReplacingOccurrencesOfString:@":" withString:@""];
    return str;
}
-(NSArray *)trimEmpty:(NSArray *)ar{
    NSMutableArray *arResult = [NSMutableArray array];
    bool isAllEmpty = true;
    for (NSString *s in ar) {
        if(s.length>0){
            for(int i =0;i<s.length;i++){
                unichar c = [s characterAtIndex:i];
                if(c != ' '){
                    isAllEmpty = false;
                    break;
                }
            }
            if(!isAllEmpty){
                [arResult addObject:s];
            }
        }
        
    }
    return arResult;
}
-(void)parseOC:(NSString *)filePath{
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if(content.length>0){
        NSArray *ar = [content componentsSeparatedByString:@"\n"];
        for (NSString *line in ar) {
            
            NSArray *itemsFunc = [line componentsSeparatedByString:@")"];
            if(itemsFunc.count>1){
                if([line rangeOfString:@"btnStartFix"].location!= NSNotFound){
                    NSLog(@"");
                }
                if([line rangeOfString:@"-("].location != NSNotFound
                   || [line rangeOfString:@"- ("].location != NSNotFound
                   || [line rangeOfString:@"-  ("].location != NSNotFound
                   || [line rangeOfString:@"- ("].location != NSNotFound
                   
                   ){
                    NSString *name = [itemsFunc objectAtIndex:1];
                    NSInteger sp_start = 0;
                    NSInteger sp_end = [name rangeOfString:@":"].location;
                    NSInteger sp_end2 = [name rangeOfString:@"{"].location;
                    NSInteger sp_end3 = [name rangeOfString:@";"].location;
                    if(sp_end != NSNotFound){
                        name = [name substringWithRange:NSMakeRange(sp_start, sp_end-sp_start)];
                    }
                    if(sp_end2 != NSNotFound){
                        name = [name substringWithRange:NSMakeRange(sp_start, sp_end2-sp_start)];
                    }
                    if(sp_end3 != NSNotFound){
                        name = [name substringWithRange:NSMakeRange(sp_start, sp_end3-sp_start)];
                    }
                    name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
                   
                    
                    if([[RMWordManager shareManager] isExcudleWord:name] == false){
                        if(_isGeneralNewWord){
                            NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:2]];
                            
                            [self.arrayOfMethods addObject:newname];
                        }else{
                            [self.arrayOfMethods addObject:name];
                        }
                        
                       
                    }
                }
            }
            
            NSArray *items =  [line componentsSeparatedByString:@" "];
            items = [self trimEmpty:items];
            if(items.count>1){
                
                bool isExcude = false;
                for (NSString *s in items) {
                 
                    if([s rangeOfString:@"<"].location!=NSNotFound){
                        isExcude =true;
                        break;
                    }
                    if([s rangeOfString:@"="].location!=NSNotFound){
                        isExcude =true;
                        break;
                    }
                    if([s rangeOfString:@"^"].location!=NSNotFound){
                        isExcude =true;
                        break;
                    }
                }
                
                for(int i =0;i<items.count;i++){
                    NSString *str  = [items objectAtIndex:i];
                    
                    //枚举类型
                    if([str isEqualToString:@"enum"]){
                        if(i+1<items.count){
                            NSString *name = [self trimString:[items objectAtIndex:i+1]];
                            NSInteger sp = [name rangeOfString:@":"].location;
                            if(sp != NSNotFound){
                                name = [name substringToIndex:sp];
                            }
                            NSInteger sp2 = [name rangeOfString:@"{"].location;
                            if(sp2 != NSNotFound){
                                name = [name substringToIndex:sp2];
                            }
                            
                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                if(_isGeneralNewWord){
                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:0]];
                                    [self.arrayOfClassName addObject:newname];
                                }else{
                                    [self.arrayOfClassName addObject:name];
                                }
                               
                            }
                                                    
                        }
                      
                    }
                                        
                    
                    if([str isEqualToString:@"@interface"]){
                        if(i+1<items.count){
                            NSString *name = [self trimString:[items objectAtIndex:i+1]];
                            NSInteger sp = [name rangeOfString:@"("].location;
                            if(sp != NSNotFound){
                                name = [name substringToIndex:sp];
                            }
                          
                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                if(_isGeneralNewWord){
                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:0]];
                                    [self.arrayOfClassName addObject:newname];
                                }else{
                                    [self.arrayOfClassName addObject:name];
                                }
                               
                            }
                                                    
                        }
                      
                    }
                   
                    if([str rangeOfString:@"@property"].location !=NSNotFound
                      
                       ){
                        if(!isExcude){
                            NSString *name = [items lastObject];
                            NSInteger sp = [name rangeOfString:@";"].location;
                            if(sp != NSNotFound){
                                name = [name substringToIndex:sp];
                            }
                            name = [name stringByReplacingOccurrencesOfString:@"*" withString:@""];
                            if([name isEqualToString:@"isSucceed)"]){
                                int g = 0;
                            }
                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                if(_isGeneralNewWord){
                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:1]];
                                    [self.arrayOfPropertys addObject:newname];
                                }else{
                                    [self.arrayOfPropertys addObject:name];
                                }
                            }
                        }
                        

                    }
                    
                
                }
            }
        }
        
    }
    NSLog(@"");
}
-(void)parseSwift{
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:_strFilePath encoding:NSUTF8StringEncoding error:&error];
    if(content.length>0){
        NSArray *ar = [content componentsSeparatedByString:@"\n"];
        for (NSString *line in ar) {
            NSArray *items =  [line componentsSeparatedByString:@" "];
            items = [self trimEmpty:items];
            if(items.count>1){
                
                bool isExcude = false;
                for (NSString *s in items) {
                 
                    if([s rangeOfString:@"<"].location!=NSNotFound){
                        isExcude =true;
                        break;
                    }
                    if([s rangeOfString:@"="].location!=NSNotFound){
                        isExcude =true;
                        break;
                    }
                }
                
                for(int i =0;i<items.count;i++){
                    NSString *str  = [items objectAtIndex:i];
                    
                    //枚举类型
                    if([str isEqualToString:@"enum"]){
                        if(i+1<items.count){
                            NSString *name = [items objectAtIndex:i+1];
                            NSRange range = [name rangeOfString:@":"];
                            if(range.location != NSNotFound){
                                name = [name substringToIndex:range.location];
                                NSLog(@"");
                            }
                            name = [name stringByReplacingOccurrencesOfString:@"{" withString:@""];
                            
                           // NSString *name = [self trimString:[items objectAtIndex:i+1]];
                            NSInteger sp = [name rangeOfString:@":"].location;
                            if(sp != NSNotFound){
                                name = [name substringToIndex:sp];
                            }
                            NSInteger sp2 = [name rangeOfString:@"{"].location;
                            if(sp2 != NSNotFound){
                                name = [name substringToIndex:sp2];
                            }
                            
                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                if(_isGeneralNewWord){
                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:0]];
                                    [self.arrayOfClassName addObject:newname];
                                }else{
                                    [self.arrayOfClassName addObject:name];
                                }
                               
                            }
                                                    
                        }
                      
                    }
                    
//                    if([str isEqualToString:@"case"]){
//                        if(i+1<items.count){
//                            NSString *name = [self trimString:[items objectAtIndex:i+1]];
//                            NSInteger sp = [name rangeOfString:@":"].location;
//                            if(sp != NSNotFound){
//                                name = [name substringToIndex:sp];
//                            }
//
//                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
//                                if(_isGeneralNewWord){
//                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:0]];
//                                    [self.arrayOfClassName addObject:newname];
//                                }else{
//                                    [self.arrayOfClassName addObject:name];
//                                }
//
//                            }
//
//                        }
//
//                    }
                    
                    
                    
                    if([str isEqualToString:@"class"]){
                        
                        if(i+1<items.count){
                            NSString *name = [items objectAtIndex:i+1];// [self trimString:[items objectAtIndex:i+1]];
                            NSRange range = [name rangeOfString:@":"];
                            if(range.location != NSNotFound){
                                name = [name substringToIndex:range.location];
                                NSLog(@"");
                            }
                            name = [name stringByReplacingOccurrencesOfString:@"{" withString:@""];
                            
                            if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                if(_isGeneralNewWord){
                                    NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:0]];
                                    [self.arrayOfClassName addObject:newname];
                                }else{
                                    [self.arrayOfClassName addObject:name];
                                }
                               
                            }
                            
                           
                            
                                                    
                        }
                      
                    }
                   
                    if([str isEqualToString:@"private"]
                       ||[str isEqualToString:@"public"]
                       ||[str isEqualToString:@"internal"]
                       ||[str isEqualToString:@"@IBOutlet"]
                       
                       
                       ){
                        NSString *strKey = @"";
                        int indexKey = -1;
                        int index = i;
                        if([str isEqualToString:@"@IBOutlet"]){
                            
                            if(i+2<items.count){
                                strKey  = [items objectAtIndex:i+2];
                                index = i+1;
                                indexKey = i+3;
                            }
                        }else{
                            strKey  = [items objectAtIndex:i+1];
                            indexKey = i + 2;
                           
                            
                        }
                        
                        if([strKey isEqualToString:@"let"]||[strKey isEqualToString:@"var"]){
                            if(indexKey<items.count){
                                NSString *name = [items objectAtIndex:indexKey];
                                NSInteger sp = [name rangeOfString:@":"].location;
                                if(sp != NSNotFound){
                                    name = [name substringToIndex:sp];
                                }
                               
                                if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                    if(_isGeneralNewWord){
                                        NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:1]];
                                        [self.arrayOfPropertys addObject:newname];
                                    }else{
                                        [self.arrayOfPropertys addObject:name];
                                    }
                                }
                                
                            }
                        }
                        
                    }
                    
                    if([str isEqualToString:@"func"]){
                        if(i+1<items.count){
                            bool isExcude = false;
                            for (NSString *s in items) {
                                if([s rangeOfString:@"override"].location!=NSNotFound){
                                    isExcude = true;
                                    break;
                                }
                                if([s rangeOfString:@"<"].location!=NSNotFound){
                                    isExcude =true;
                                    break;
                                }
                                if([s rangeOfString:@"="].location!=NSNotFound){
                                    isExcude =true;
                                    break;
                                }
                            }
                            if(!isExcude){
                                NSString *name = [items objectAtIndex:i+1];
                                NSInteger sp = [name rangeOfString:@"("].location;
                                if(sp != NSNotFound){
                                    name = [name substringToIndex:sp];
                                }
                               
                               
                                if([[RMWordManager shareManager] isExcudleWord:name] == false){
                                    if(_isGeneralNewWord){
                                        NSString *newname = [NSString stringWithFormat:@"%@->%@",name,[RMWordManager.shareManager generalNewWord:2]];
                                        
                                        [self.arrayOfMethods addObject:newname];
                                    }else{
                                        [self.arrayOfMethods addObject:name];
                                    }
                                    
                                   
                                }
                            }
                            
                           
                        }
                       
                    }
                }
            }
        }
        
    }
    NSLog(@"");
}
-(BOOL)scan:(BOOL)isGeneralNew{
    _isGeneralNewWord = isGeneralNew;
    if(self.strFilePath){
        if([NSFileManager.defaultManager fileExistsAtPath:_strFilePath]){
             NSInteger lo =  [_strFilePath rangeOfString:@"." options:NSBackwardsSearch].location;
            if(lo != NSNotFound){
                NSString *str =  [_strFilePath substringFromIndex:lo];
                if([str isEqualToString:@".swift"]
                   
                   ){
                    [self parseSwift];
                    return true;
                }
                if([str isEqualToString:@".m"]){
                    [self parseOC:_strFilePath];
                    NSString*hfile = [[_strFilePath substringToIndex:lo] stringByAppendingString:@".h"];
                    if([NSFileManager.defaultManager fileExistsAtPath:hfile]){
                        [self parseOC:hfile];
                    }
                    return true;
                }
            }
        }
    }
    return false;
}
@end

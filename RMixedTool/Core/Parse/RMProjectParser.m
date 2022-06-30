//
//  RMProjectParser.m
//  RMixedTool
//
//  Created by ron on 2021/6/24.
//

#import "RMProjectParser.h"

@interface RMProjectParser(){
    NSDictionary * _dicOfProjectConfigs;
}

@end

@implementation RMProjectParser

static RMProjectParser* parse = nil;
+(RMProjectParser *)shareParser{
    if(parse == nil){
        parse = [RMProjectParser new];
    }
    return parse;
}
-(int)findString:(NSArray *)strs str:(NSString *)str{
    for(int i =0;i<strs.count;i++){
        NSString * s = [strs objectAtIndex:i];
        if([s rangeOfString:str].location != NSNotFound){
            return i;
        }
    }
    return -1;
}
-(NSString *)trimComment:(NSString *)str{
    NSArray *a = [str componentsSeparatedByString:@" "];
    if(a.count>=1){
        return a.firstObject;
    }
    return str;
}
-(NSDictionary *)parseDic:(NSArray *)contentLines{
    NSMutableDictionary *dic = nil;
    for(int i =0;i<contentLines.count;i++){
        NSString * s = [contentLines objectAtIndex:i];
        if([s rangeOfString:@"{"].location != NSNotFound){
            NSArray *a = [s componentsSeparatedByString:@"="];
            if(a.count>1){
                if(dic == nil){
                    dic = [NSMutableDictionary dictionary];
                }
                [dic setObject:a.firstObject forKey:@"uid"];
            }
        }else{
            if([s rangeOfString:@"="].location != NSNotFound){
                NSArray *a = [s componentsSeparatedByString:@"="];
                if(dic){
                    NSString *value = a.lastObject;
                    if([value rangeOfString:@"("].location != NSNotFound){
                        
                    }else{
                        [dic setValue:[self trimComment:value] forKey:a.firstObject];
                    }
                }
            }
        }
        
    }
    return dic;
}

-(NSDictionary*)parseNode:(NSString *)content root:(NSDictionary *)dicRoot{
   
    //    NSMutableArray *sections = [NSMutableArray array];
    //    NSMutableDictionary *dicSectionNow  = nil;
    //    for(int i =0;i<lines.count;i++){
    //        NSString *str = [lines objectAtIndex:i];
    //        if([str rangeOfString:@"/* Begin"].location != NSNotFound){
    //            NSMutableDictionary *dicSection = [NSMutableDictionary dictionary];
    //            [dicSection setValue:str forKey:@"section_key"];
    //            [sections addObject:dicSection];
    //            NSMutableArray *arraycontents = [NSMutableArray array];
    //            [dicSection setValue:arraycontents forKey:@"content"];
    //            dicSectionNow = dicSection;
    //        }
    //        if([str rangeOfString:@"{"].location!=NSNotFound && [str rangeOfString:@"="].location!=NSNotFound
    //           && dicSectionNow){
    //            int index = [self findString:[lines subarrayWithRange:NSMakeRange(i, lines.count-i)] str:@"}"];
    //             if(index>=0){
    //                 if(dicSectionNow){
    //                     NSMutableArray *contents =[dicSectionNow valueForKey:@"content"];
    //                     [contents addObject:[self parseDic:[lines subarrayWithRange:NSMakeRange(i, index+1)]]];
    //                 }
    //             }
    //        }
    
    //  }
    // return sections;
    return nil;
}
-(BOOL)isChar:(unichar)c{
    if((c>='a' && c<='z')
       ||(c>='A' && c<= 'Z')
       ||(c>='0' && c<= '9')
       || c=='/'
       || c=='.'
       ){
        return true;
    }
    return false;
}
- (NSDictionary *)parseProjectConfigV2:(NSString *)filePath{
    NSMutableDictionary *dicResult = [NSMutableDictionary dictionary];
    if([NSFileManager.defaultManager fileExistsAtPath:filePath]){
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if(content.length>0){
            return [self parseNode:content root:dicResult];
        }
    }
    return nil;
}
-(NSArray *)getTargetsInfo{
    NSMutableArray *ar = [NSMutableArray array];
    if(_dicOfProjectConfigs){
        NSDictionary *dic = _dicOfProjectConfigs;
        if(dic && [dic.allKeys containsObject:@"objects"]){
            NSDictionary *objs = [dic objectForKey:@"objects"];
            for (NSString *key in objs.allKeys) {
                NSDictionary *v = [objs objectForKey:key];
                if([v.allKeys containsObject:@"isa"]){
                    NSString *type = [v objectForKey:@"isa"];
                    if([type isEqualToString:@"PBXNativeTarget"]){
                        [ar addObject:v];
                    }
                }
            }
        }
    }
    return ar;
}
- (NSDictionary *)parseProjectConfig:(NSString *)filePath{
    if([NSFileManager.defaultManager fileExistsAtPath:filePath]){
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        content = [content stringByReplacingOccurrencesOfString:@"// !$*UTF8*$!" withString:@""];
        //去掉注释。
        int findStart = -1;
        int endStart = -1;
        if(content.length>0){
            for(int i =0;i<content.length;i++){
                unichar c = [content characterAtIndex:i];
                if(c == '/' && [content characterAtIndex:i+1] == '*'){
                    findStart = i;
                }
                if(c == '*' &&  [content characterAtIndex:i+1] == '/'){
                    endStart = i+1;
                    if(findStart>=0){
                        content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, endStart-findStart+1) withString:@""];
                        i = 0;
                    }
                }
                
            }
        }
        
        //去掉保护宏变量的行
        NSArray *ar = [content componentsSeparatedByString:@"\n"];
        for(NSString * s in ar){
            if([s rangeOfString:@"${"].location != NSNotFound){
                content = [content stringByReplacingOccurrencesOfString:s withString:@""];
            }
            if([s rangeOfString:@"$("].location != NSNotFound){
                content = [content stringByReplacingOccurrencesOfString:s withString:@""];
            }
        }
        
        //去除字符串中保护 = 的行。
        NSArray *ar2 = [content componentsSeparatedByString:@"\n"];
        for(NSString * s in ar2){
            NSInteger start =0;
            NSInteger end = 0;
            start = [s rangeOfString:@"\""].location;
            end = [s rangeOfString:@"\""  options:NSBackwardsSearch].location;
            if(start!=NSNotFound && end != NSNotFound && end>start){
                NSInteger specailIndex = [s rangeOfString:@"="].location;
                if(specailIndex>start && specailIndex<end){
                    content = [content stringByReplacingOccurrencesOfString:s withString:@""];
                }
                
            }
            
        }
        
        
        int start = [content rangeOfString:@"\n"].location;
        content = [content substringFromIndex:start];
        
        //去除格式符号。
        content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
        content = [content stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        
        
        //改造里面的数组符号json的格式。
        for(int i =0;i<content.length;i++){
            unichar c = [content characterAtIndex:i];
            int arrayStart = -1;
            int arrayEnd = -1;
            if(c == '(' ){
                arrayStart = i;
            }
            if(arrayStart>=0){
                int j = i+1;
                while (j<content.length) {
                    if([content characterAtIndex:j] == ')'){
                        arrayEnd = j;
                        break;
                    }
                    j++;
                }
            }
            if(arrayStart>=0 && arrayEnd>=0){
                content = [content stringByReplacingCharactersInRange:NSMakeRange(arrayStart,1) withString:@"["];
                content = [content stringByReplacingCharactersInRange:NSMakeRange(arrayEnd, 1) withString:@"]"];
                
                
                int s = arrayStart+1;
                int e = -1;
                for(NSInteger k = arrayStart;k<arrayEnd;k++){
                    
                    if([content characterAtIndex:k] == ',' && [content characterAtIndex:k-1] != '}'){
                        e = k;
                    }
                    
                    
                    bool isLast = false;
                    if([content characterAtIndex:k+1] == ']'){
                        isLast = true;
                      
                    }
                    if(s>=0 && e>=0){
                        NSString *con = [content substringWithRange:NSMakeRange(s, e-s)];
                        int rleng = con.length;
                        con = [con stringByReplacingOccurrencesOfString:@" " withString:@""];
                        if(con.length>0){
                            NSLog(@"replace length %i,will replace %@",con.length,con);
                            
                            if ([con rangeOfString:@";"].location != NSNotFound){
                                NSLog(@"xxx");
                            }
                                
                            con = isLast?[NSString stringWithFormat:@"{%@:%@}",con,con]: [NSString stringWithFormat:@"{%@:%@};",con,con];
                            
                            
                            
                            content = [content stringByReplacingCharactersInRange:NSMakeRange(s, e-s+1) withString:con];
                            
                            int increase = con.length - (e-s+1);
                            
                            arrayEnd += increase; //(con.length - rleng);
                            
                            NSLog(@"文本扩大了 %i",increase);
                            
                            if([con rangeOfString:@"8EA0DE2D28324FF3008C9DBC"].location != NSNotFound){
                                NSLog(@"");
                            }
                           
                            k = e + increase;//(con.length - rleng);
                            s = k+1;
                            e = -1;
                            
                            
                        }
                    }
                    
                }
                
               
                NSLog(@"数组 end");
                //i = 0;
                i = arrayEnd;
                arrayStart = -1;
                arrayEnd = -1;
            }
        }
        
        
        //处理={}
       
        content = [content stringByReplacingOccurrencesOfString:@",]" withString:@"]"];
        content = [content stringByReplacingOccurrencesOfString:@";]" withString:@"]"];
        
        //将，号转化为 #，因为，为json的关键符合。
        content = [content stringByReplacingOccurrencesOfString:@"," withString:@"#"];
        
        //将字符双引号字符转为其他 号转化为 #，因为，为json的关键符合。
        content = [content stringByReplacingOccurrencesOfString:@"," withString:@"#"];
        
        
        content = [content stringByReplacingOccurrencesOfString:@"=" withString:@":"];
        content = [content stringByReplacingOccurrencesOfString:@",}" withString:@"}"];
        content = [content stringByReplacingOccurrencesOfString:@";}" withString:@"}"];
        content = [content stringByReplacingOccurrencesOfString:@";" withString:@","];
        
        findStart = -1;
        for(int i =0;i<content.length;i++){
            unichar c = [content characterAtIndex:i];
            if(c == '{' && [self isChar:[content characterAtIndex:i+1]] ){
                findStart = i;
                
                BOOL ismacro = false;
                if(i-1>=0){
                    if([content characterAtIndex:i-1] == '$'){
                        ismacro = true;
                    }
                }
                if(!ismacro){
                    content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@"{\""];
                }
            }
            
            if(c == '}' && [self isChar:[content characterAtIndex:i-1]] ){
                findStart = i;
                
                int j = i-1;
                bool ismacro = false;
                while (j>=0) {
                    
                    if(j-1>=0){
                        if([content characterAtIndex:j] == '{' && [content characterAtIndex:j-1] == '$'){
                            ismacro = true;
                            break;;
                        }
                    }
                    j--;
                }
                
                if(!ismacro){
                    content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@"\"}"];
                }
            }
            
            
            if(c == ':' && [self isChar:[content characterAtIndex:i+1]] ){
                findStart = i;
                content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@":\""];
            }
            
            if(c == ':' && [self isChar:[content characterAtIndex:i-1]] ){
                findStart = i;
                content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@"\":"];
                
            }
            
          
            if(c == ',' && [self isChar:[content characterAtIndex:i+1]] ){

                findStart = i;
                content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@",\""];
                
            }
            
            if(c == ',' && [self isChar:[content characterAtIndex:i-1]] ){
                findStart = i;
                content = [content stringByReplacingCharactersInRange:NSMakeRange(findStart, 1) withString:@"\","];
            }
            
        }
        
       NSDictionary *dic =   [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        _dicOfProjectConfigs = dic;
        return dic;
    }
    return nil;
}
@end

//
//  RMProjectManager.m
//  RMixedTool
//
//  Created by ron on 2021/6/25.
//

#import "RMProjectManager.h"
#import "RMWordManager.h"
@interface RMProjectManager(){
    NSString *_strProjectConfigPath;
    NSArray *_arrayProjectTargets;
    NSDictionary*_dicProjectInfo;
    NSString *_pathOfMixConfig;
    NSDictionary*_dicTarget;
    NSMutableArray*_arrayOfAllFilesPath;
    
    NSDictionary *_dicMixConfig;
    NSDictionary *_dicMixConfig_Orign;
    NSArray *_arrayOfAllFilesPath_target;
    NSString *_targetName;
    
    dispatch_queue_t _queueIO ;
}
@property(nonatomic,strong)NSString *projectDir;
@end

@implementation RMProjectManager

static RMProjectManager* manager = nil;

+(RMProjectManager *)shareManager{
    if(manager == nil){
        manager = [[RMProjectManager alloc] init];
        
    }
    return manager;
}
- (instancetype)init{
    self = [super init];
    _queueIO = dispatch_queue_create("queue_io", DISPATCH_QUEUE_SERIAL);
    return self;
}
-(void)addExcueWords:(NSArray *)ars{
    [[RMWordManager shareManager] addExcudeWords:ars];
}
-(NSDictionary*)searchObj:(NSString *)uuid{
    NSDictionary*objs = [_dicProjectInfo objectForKey:@"objects"];
    for (NSString *key in objs) {
        if([key isEqualTo:uuid]){
            return [objs objectForKey:key];
        }
    }
    return nil;
}
-(NSString *)getFilePath:(NSString *)filename{
    for (NSString*str in _arrayOfAllFilesPath) {
        NSString *filename2 = [NSString stringWithFormat:@"/%@",filename];
        if([str rangeOfString:filename2].location != NSNotFound){
            return str;
        }
    }
    return nil;
}

-(NSArray *)getTargetSourceFiles:(NSString *)targetName{
    if (targetName == nil) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    if(_arrayProjectTargets){
        for (NSDictionary *dic in _arrayProjectTargets) {
            if([targetName rangeOfString:[dic objectForKey:@"name"]].location != NSNotFound){
                NSMutableArray * array = [NSMutableArray array];
                NSArray *buildPhase = [dic objectForKey:@"buildPhases"];
               
                for (NSDictionary* d in buildPhase) {
                    NSString *uid = d.allKeys.firstObject;
                    NSDictionary *dic = [self searchObj:uid];
                   
                    if(dic){
                        if([[dic objectForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]
                           ||
                           [[dic objectForKey:@"isa"] isEqualToString:@"PBXResourcesBuildPhase"]
                           ){
                            [array addObject:dic];
                        }
                       
                    }
                }
                
                for (NSDictionary*dicSection in array) {
                    NSArray *arrayFiles = [dicSection objectForKey:@"files"];
                    
                    for (NSDictionary*dicKey in arrayFiles) {
                        NSDictionary *d = [self searchObj:dicKey.allKeys.firstObject];
                        
                        if(d){
                            if([d.allKeys containsObject:@"fileRef"]){
                                NSString *uid = [d objectForKey:@"fileRef"];
                                NSDictionary*dic2 =  [self searchObj:uid];
                                if(dic2){
                                    
                                    NSString *filename = [dic2 objectForKey:@"path"];
                                    NSString *filepath =  [self getFilePath:filename];
                                    if(filepath){
                                        //如果是.m文件，需要增加头文件进去混淆。
                                        NSRange r = [filepath rangeOfString:@".m" options:NSBackwardsSearch];
                                        if(r.location!=NSNotFound){
                                            NSString *s =  [[filepath substringToIndex:r.location] stringByAppendingString:@".h"];
                                            [result addObject:s];
                                        }
                                        [result addObject:filepath];
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
            }
           
        }
        
    }
    return result;
}
-(NSDictionary*)generalWithTargetItem:(NSDictionary *)dicOfTarget{
    if(dicOfTarget == nil)return nil;
    
    NSDictionary *_dicOrigin = nil;
    NSString *name = [dicOfTarget objectForKey:@"path"];
    if(name == nil){
        name = [dicOfTarget objectForKey:@"name"];
    }
    if(_dicMixConfig_Orign){
        
        _dicOrigin =  [_dicMixConfig_Orign objectForKey:name];
    }
    NSMutableDictionary *dicRoot =  [NSMutableDictionary dictionary];
    NSMutableArray *arrayFiles = [NSMutableArray array];
    
    
    NSMutableDictionary *dicWords = [NSMutableDictionary dictionary];
    if(_dicOrigin){
        dicWords = [NSMutableDictionary dictionaryWithDictionary:[_dicOrigin objectForKey:@"word"]];
    }
    
    [dicRoot setValue:arrayFiles forKey:@"path"];
    [dicRoot setValue:dicWords forKey:@"word"];
    
    NSString *filename = [dicOfTarget objectForKey:@"name"];
    NSArray *files =   [self getTargetSourceFiles:filename];
    for (NSString*path in files) {
        [arrayFiles addObject:path];
        RMSourceScanner*scanner  =  [[RMSourceScanner alloc] initWithPath:path];
        bool isS =  [scanner scan:false];
        if(isS){
            RMSourceScanner*scanner  =  [[RMSourceScanner alloc] initWithPath:path];
            bool isS =  [scanner scan:true];
            if(isS){
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                NSMutableArray* arrayAllWords = [NSMutableArray array];
             
                [dic setValue:scanner.arrayOfClassName forKey:@"class"];
                [dic setValue:scanner.arrayOfMethods forKey:@"method"];
                [dic setValue:scanner.arrayOfPropertys forKey:@"property"];
                [arrayAllWords addObjectsFromArray:scanner.arrayOfClassName];
                [arrayAllWords addObjectsFromArray:scanner.arrayOfMethods];
                [arrayAllWords addObjectsFromArray:scanner.arrayOfPropertys];
            
                for (NSString *w in arrayAllWords) {
                    NSArray *ar = [w componentsSeparatedByString:@"->"];
                    if(ar.count == 2){
                        NSString *key = ar.firstObject;
                        NSDictionary *dicWords_origin = [_dicOrigin objectForKey:@"word"];
                        if(![dicWords_origin.allKeys containsObject:key]){
                            [dicWords setValue:ar.lastObject forKey:ar.firstObject];
                        }
                        
                    }
                   
                }
            }
        }
    }
    return @{name:dicRoot};
   
}
-(NSDictionary *)generalOrUpdateMixConfigFile:(NSString *)config target:(nonnull NSString *)targetName{
    
    _pathOfMixConfig = config;
    NSMutableDictionary *dicResult = nil;
    if(_pathOfMixConfig){
        NSData *data = [NSData dataWithContentsOfFile:_pathOfMixConfig];
        if(data){
          NSDictionary*dic =   [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if(dic){
                _dicMixConfig_Orign = dic;
                dicResult = [NSMutableDictionary dictionaryWithDictionary:dic];
            }
        }
    }
    if(!dicResult){
        dicResult = [NSMutableDictionary dictionary];
    }
    _targetName = targetName;
    for (NSDictionary*dic in _arrayProjectTargets) {
        if([[dic objectForKey:@"name"] isEqualToString:targetName]){
            _dicTarget = dic;
            break;;
        }
    }
    
    if(_dicTarget){
        NSMutableArray * array = [NSMutableArray array];
        NSArray *buildPhase = [_dicTarget objectForKey:@"buildPhases"];
        NSDictionary *dicOfFramework = nil;
        for (NSDictionary* d in buildPhase) {
            NSString *uid = d.allKeys.firstObject;
            NSDictionary *dic = [self searchObj:uid];
           
            if(dic){
                if([[dic objectForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]
                   ||
                   [[dic objectForKey:@"isa"] isEqualToString:@"PBXResourcesBuildPhase"]
                   ){
                    [array addObject:dic];
                }
                if([[dic objectForKey:@"isa"] isEqualToString:@"PBXFrameworksBuildPhase"]){
                    dicOfFramework = dic;
                    
                }
            }
        }
        
        //
        //先扫描依赖的库。依赖库符合不混淆。
//        NSArray *arrayFrameworkFiles = [dicOfFramework objectForKey:@"files"];
//        for (NSDictionary*dicKey in arrayFrameworkFiles) {
//            NSDictionary *d = [self searchObj:dicKey.allKeys.firstObject];
//
//            if([d.allKeys containsObject:@"fileRef"]){
//                NSString *uid = [d objectForKey:@"fileRef"];
//                NSDictionary*dic2 =  [self searchObj:uid];
//                if(dic2){
//                   NSDictionary *dic = [self generalWithTargetItem:dic2];
//                    [dicResult addEntriesFromDictionary:dic];
////                    NSString *filename = [dic2 objectForKey:@"path"];
////                    NSArray *files =   [self getTargetSourceFiles:filename];
////                    for (NSString*path in files) {
////                        RMSourceScanner*scanner  =  [[RMSourceScanner alloc] initWithPath:path];
////                        bool isS =  [scanner scan:false];
////                        if(isS){
////                            NSMutableArray* arrayAllWords = [NSMutableArray array];
////                            [arrayAllWords addObjectsFromArray:scanner.arrayOfClassName];
////                            [arrayAllWords addObjectsFromArray:scanner.arrayOfMethods];
////                            [arrayAllWords addObjectsFromArray:scanner.arrayOfPropertys];
////
////                            [[RMWordManager shareManager] addExcudeWords:arrayAllWords];
////                            NSLog(@"%@",[arrayAllWords description]);
////                        }
////                    }
//                }
//            }
//        }
        
        NSDictionary *dic = [self generalWithTargetItem:_dicTarget];
        [dicResult addEntriesFromDictionary:dic];
        _dicMixConfig = dicResult;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dicResult options:NSJSONWritingPrettyPrinted error:nil];
        [data writeToFile:_pathOfMixConfig atomically:YES];
        return dicResult;
    }
    return nil;
}
-(BOOL)isNumberOrLetter:(unichar)c fileType:(NSString *)type line:(NSString *)lineString{
    if(
       (c>='0' && c<= '9')
       ||(c>='a' && c<= 'z')
       ||(c>='A' && c<= 'Z')
       ||(c == '_')
       ){
       
        return true;
    }else{
        if([type isEqualToString:@"swift"]
           ||[type isEqualToString:@"m"]
           ||[type isEqualToString:@"h"]
           ){
            
            //是否包含出时候Xib的部分，如果包含，需要修改字符串
            
            bool isInitXib = false;
            if ([lineString rangeOfString:@"initWithNibName"].location != NSNotFound
                ||[lineString rangeOfString:@"nibName"].location != NSNotFound
                ||[lineString rangeOfString:@"xibName"].location != NSNotFound
                ){
                isInitXib = true;
            }
            
           
           
            //cell 的id 需要同步更改
            if (
                [lineString rangeOfString:@"withIdentifier"].location != NSNotFound
                || [lineString rangeOfString:@"withReuseIdentifier"].location != NSNotFound
                
                ){
                return  false;
            }
            
            
            
            //对于字符串，一般不替换字面字符串，但是xib 初始化例外，因xib文件名会被更改，相应的初始化字符串也需要替换。
            if(c == '"' &&  isInitXib == false)
              {
                return true;
            }
        }
    }
    return false;
}
-(NSString *)replaceString:(NSString *)content whichWord:(NSString *)wordOring replaseString:(NSString *)replaceString fileType:(NSString *)fileType{
    NSString *result = content;
    
    for(NSInteger i =0;i<result.length;i++){
        
        NSRange range =  [result rangeOfString:wordOring options:NSLiteralSearch range:NSMakeRange(i, result.length-1-i)];
        
        NSString *line = @"";
        
        
        NSInteger j = range.location;
        if(j!=NSNotFound){
            while(j-1>=0){
                j--;
                if([result characterAtIndex:j] == '\n'
                   ||[result characterAtIndex:j] == '<'){
                    line = [result substringWithRange:NSMakeRange(j, range.location-j)];
                    break;
                }
            }
        }
        
        if(range.location!=NSNotFound){
            if(range.location == 0 || (range.location-1>=0 && ![self isNumberOrLetter:[result characterAtIndex:range.location-1] fileType:fileType line:line])){
               
                if([fileType isEqualToString:@"xib"]){
                    if([wordOring isEqualTo:@"imageViewTab0"]){
                        NSLog(@"");
                    }
                    bool shouldProcess = false;
                  
                    //xib只处理<action 和 <outle开头的行。
                    if([line rangeOfString:@"<action"].location != NSNotFound
                       ||
                       [line rangeOfString:@"<outlet"].location != NSNotFound
                       ||
                       [line rangeOfString:@"customClass"].location != NSNotFound
                       |
                       [line rangeOfString:@"reuseIdentifier"].location != NSNotFound
                       
                       ){
                        shouldProcess = true;
                    }
                    if(!shouldProcess){
                        i = range.location;
                        continue;
                    }
                }
                
                NSInteger lastIndex = range.location+range.length -1;
                if(lastIndex == result.length-1  ||
                   (lastIndex+1 < result.length && ![self isNumberOrLetter:[result characterAtIndex:lastIndex+1] fileType:fileType line:line])){
                    
                    result = [result stringByReplacingCharactersInRange:range withString:replaceString];
                   
                    i = range.location;
                }
            }
        }else{
            break;
        }
        
    }
    
    return result;
}


/// 混淆文件
/// @param path 文件路径
/// @return 返回需要配置文件需要替换的字符
-(NSDictionary *)mixedFile:(NSString *)path{
    NSLog(@"Mixed Path %@",path);
    NSDictionary * dicReturn = nil;
    if([path rangeOfString:@".xib"].location!=NSNotFound
       || [path rangeOfString:@".swift"].location!=NSNotFound
       || [path rangeOfString:@".m"].location!=NSNotFound
       || [path rangeOfString:@".h"].location!=NSNotFound
       || [path rangeOfString:@".storyboard"].location!=NSNotFound
       
       ){
            
        NSString *fileType = @"";
       
        NSRange  r =  [path rangeOfString:@"." options:NSBackwardsSearch];
        if(r.location!=NSNotFound){
            fileType = [path substringFromIndex:r.location+1];
        }
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *words = [_dicTarget objectForKey:@"word"];
        NSString * __block pathCopy = [path copy];
        
        
        for (NSString*key in words.allKeys) {
 
            content = [self replaceString:content whichWord:key replaseString:[words objectForKey:key] fileType:fileType];
            
            //更改xib资源文件名字
            if([fileType isEqualToString:@"xib"]){
                
                NSInteger l = [path rangeOfString:@"/" options:NSBackwardsSearch].location;
                if(l!=NSNotFound){
                    NSString *filename = [path substringWithRange:NSMakeRange(l+1, r.location-l-1)];
                    if([filename isEqual:key]){
                        NSString *newPath = [path stringByReplacingOccurrencesOfString:filename withString:[words objectForKey:key]];
                        NSError *error = nil;
                        bool isSucced =  [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error];
                        NSLog(@"重命名XIB %d:%@->%@",isSucced,path,newPath);
                        if(isSucced && error == nil){
                            
                            
                            pathCopy = newPath;
                            
                        
                            dicReturn = @{[NSString stringWithFormat:@"%@.xib",key]:[NSString stringWithFormat:@"%@.xib",[words objectForKey:key]]};
                        }else{
                            NSLog(@"xxxx");
                        }
                        NSLog(@"%d:%@",isSucced,[error description]);
                    }
                }
            }
        }
        [content writeToFile:pathCopy atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
    }
    return dicReturn;
}
-(void)beginMixed{
    
    if(_dicMixConfig){
        _dicTarget = [_dicMixConfig objectForKey:_targetName];
        NSArray *paths = [_dicTarget objectForKey:@"path"];
        
        NSMutableArray *arrayChanges = [NSMutableArray array];
        dispatch_apply(paths.count, DISPATCH_APPLY_AUTO, ^(size_t iteration) {
            
            NSString *path = [paths objectAtIndex:iteration];
            //NSLog(@"Index %ld",iteration);
            NSDictionary *dic =  [self mixedFile:path];
            if (dic){
                [arrayChanges addObject:dic];
            }
            
           
        });
        
        NSString *projectContent = [NSString stringWithContentsOfFile:_strProjectConfigPath encoding:NSUTF8StringEncoding error:nil];
        for (NSDictionary *dic in arrayChanges){
                        
            if(projectContent.length>0){
                projectContent = [projectContent stringByReplacingOccurrencesOfString:dic.allKeys.firstObject withString:dic.allValues.firstObject];
            }
        }
        [projectContent writeToFile:_strProjectConfigPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"Mixed Finished");
//        for (NSString *path  in paths) {
//
//
//
//        }
    }
}
-(void)startAnalyse:(void (^)(NSError *  error, NSArray * ))result{
    _arrayOfAllFilesPath = [NSMutableArray array];
    if(self.projectDir.length == 0){
        if(result){
            NSError *e = [NSError errorWithDomain:@"" code:1 userInfo:@{@"msg":@"请先设置项目路径"}];
            result(e,nil);
            return;
        }
    }
    
    if([NSFileManager.defaultManager fileExistsAtPath:self.projectDir]){
        NSArray *files =  [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.projectDir error:nil];
        for (NSString*name in files) {
            if([name rangeOfString:@".xcodeproj"].location!=NSNotFound){
                NSString *dir2 =  [self.projectDir stringByAppendingFormat:@"/%@",name];
                NSArray *files2 =  [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir2 error:nil];
                for (NSString*name2 in files2) {
                    if([name2 rangeOfString:@"project.pbxproj"].location!=NSNotFound){
                        _strProjectConfigPath =  [dir2 stringByAppendingFormat:@"/%@",name2];
                        break;
                        
                    }
                }
            }
        }
        
        if(_strProjectConfigPath.length>0){
            NSDictionary *dic =  [RMProjectParser.shareParser parseProjectConfig:_strProjectConfigPath];
            if(dic == nil){
                NSError *e = [NSError errorWithDomain:@"" code:2 userInfo:@{@"msg":@"解析项目文件xcodeproj"}];
                result(e,nil);
                return;
            }
            _dicProjectInfo = dic;
            NSArray *targetsInfo =  [RMProjectParser.shareParser getTargetsInfo];
            _arrayProjectTargets = targetsInfo;
            NSError *e = [NSError errorWithDomain:@"" code:0 userInfo:@{@"msg":@"解析项目成功"}];
            
            //递归遍历项目路径下的文件路径。
            NSDirectoryEnumerator *directoryEnum = [NSFileManager.defaultManager enumeratorAtPath:self.projectDir];
            
                NSString *filePath;
                while (filePath = [directoryEnum nextObject]) {
                    NSString *path = [NSString stringWithFormat:@"%@/%@",self.projectDir,filePath];
                    BOOL isDir = true;
                    if([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir]){
                        if(!isDir){
                            [_arrayOfAllFilesPath addObject:path];
                        }
                    }
                    //NSLog(@"filePath = %@", filePath);
                }
            
            result(e,_arrayProjectTargets);
           
        }else{
            NSError *e = [NSError errorWithDomain:@"" code:1 userInfo:@{@"msg":@"找不到项目配置文件，请检查路径配置"}];
            result(e,nil);
            return;
        }
    }else{
        NSError *e = [NSError errorWithDomain:@"" code:1 userInfo:@{@"msg":@"项目解析失败，请检查路径配置"}];
        result(e,nil);
        return;
    }
}


-(void)config:(NSString *)projectDir{
    self.projectDir = projectDir;
}
@end

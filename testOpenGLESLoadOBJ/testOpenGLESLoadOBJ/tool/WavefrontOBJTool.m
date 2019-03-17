//
//  WavefrontOBJTool.m
//  testOpenGLESLoadOBJ
//
//  Created by Lyman Li on 2019/3/17.
//  Copyright © 2019年 Lyman Li. All rights reserved.
//

#import "WavefrontOBJTool.h"

@interface WavefrontOBJTool ()

@property (strong, nonatomic) NSMutableData *positionData;
@property (strong, nonatomic) NSMutableData *uvData;
@property (strong, nonatomic) NSMutableData *normalData;

@property (strong, nonatomic) NSMutableData *positionIndexData;
@property (strong, nonatomic) NSMutableData *uvIndexData;
@property (strong, nonatomic) NSMutableData *normalIndexData;

@end

@implementation WavefrontOBJTool

- (instancetype)init {
    self = [super init];
    if (self) {
        self.positionData = [[NSMutableData alloc] init];
        self.uvData = [[NSMutableData alloc] init];
        self.normalData = [[NSMutableData alloc] init];
        self.positionIndexData = [[NSMutableData alloc] init];
        self.uvIndexData = [[NSMutableData alloc] init];
        self.normalIndexData = [[NSMutableData alloc] init];
    }
    return self;
}

- (SenceVertex *)loadDataFromObj:(NSString *)filePath {
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray<NSString *> *lines = [fileContent componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if (line.length >= 2) {
            if ([line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
                [self processVertexLine:line];
            } else if ([line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
                [self processNormalLine:line];
            } else if ([line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
                [self processUVLine:line];
            } else if ([line characterAtIndex:0] == 'f' && [line characterAtIndex:1] == ' ') {
                [self processFaceIndexLine:line];
            }
        }
    }
    SenceVertex *vertexs = [self decompressToVertexArray];
    
    return vertexs;
}

- (void)processVertexLine:(NSString *)line {
    static NSString *pattern = @"v\\s*([\\-0-9]*\\.[\\-0-9]*)\\s*([\\-0-9]*\\.[\\-0-9]*)\\s*([\\-0-9]*\\.[\\-0-9]*)";
    static NSRegularExpression *regexExp = nil;
    if (regexExp == nil) {
        regexExp = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    NSArray * matchResults = [regexExp matchesInString:line options:0 range:NSMakeRange(0, line.length)];
    for (NSTextCheckingResult *result in matchResults) {
        NSUInteger rangeCount = result.numberOfRanges;
        if (rangeCount == 4) {
            float x = [[line substringWithRange: [result rangeAtIndex:1]] floatValue];
            float y = [[line substringWithRange: [result rangeAtIndex:2]] floatValue];
            float z = [[line substringWithRange: [result rangeAtIndex:3]] floatValue];
            [self.positionData appendBytes:(void *)(&x) length:sizeof(float)];
            [self.positionData appendBytes:(void *)(&y) length:sizeof(float)];
            [self.positionData appendBytes:(void *)(&z) length:sizeof(float)];
        }
    }
}

- (void)processNormalLine:(NSString *)line {
    static NSString *pattern = @"vn\\s*([\\-0-9]*\\.[\\-0-9]*)\\s*([\\-0-9]*\\.[\\-0-9]*)\\s*([\\-0-9]*\\.[\\-0-9]*)";
    static NSRegularExpression *regexExp = nil;
    if (regexExp == nil) {
        regexExp = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    NSArray * matchResults = [regexExp matchesInString:line options:0 range:NSMakeRange(0, line.length)];
    for (NSTextCheckingResult *result in matchResults) {
        NSUInteger rangeCount = result.numberOfRanges;
        if (rangeCount == 4) {
            float x = [[line substringWithRange: [result rangeAtIndex:1]] floatValue];
            float y = [[line substringWithRange: [result rangeAtIndex:2]] floatValue];
            float z = [[line substringWithRange: [result rangeAtIndex:3]] floatValue];
            [self.normalData appendBytes:(void *)(&x) length:sizeof(float)];
            [self.normalData appendBytes:(void *)(&y) length:sizeof(float)];
            [self.normalData appendBytes:(void *)(&z) length:sizeof(float)];
        }
    }
}

- (void)processUVLine:(NSString *)line {
    static NSString *pattern = @"vt\\s*([\\-0-9]*\\.[\\-0-9]*)\\s*([\\-0-9]*\\.[\\-0-9]*)";
    static NSRegularExpression *regexExp = nil;
    if (regexExp == nil) {
        regexExp = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    NSArray * matchResults = [regexExp matchesInString:line options:0 range:NSMakeRange(0, line.length)];
    for (NSTextCheckingResult *result in matchResults) {
        NSUInteger rangeCount = result.numberOfRanges;
        if (rangeCount == 3) {
            float x = [[line substringWithRange: [result rangeAtIndex:1]] floatValue];
            float y = [[line substringWithRange: [result rangeAtIndex:2]] floatValue];
            [self.uvData appendBytes:(void *)(&x) length:sizeof(float)];
            [self.uvData appendBytes:(void *)(&y) length:sizeof(float)];
        }
    }
}

- (void)processFaceIndexLine:(NSString *)line {
    static NSString *pattern = @"f\\s*([0-9]*)/([0-9]*)/([0-9]*)\\s*([0-9]*)/([0-9]*)/([0-9]*)\\s*([0-9]*)/([0-9]*)/([0-9]*)";
    static NSRegularExpression *regexExp = nil;
    if (regexExp == nil) {
        regexExp = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    }
    NSArray * matchResults = [regexExp matchesInString:line options:0 range:NSMakeRange(0, line.length)];
    for (NSTextCheckingResult *result in matchResults) {
        NSUInteger rangeCount = result.numberOfRanges;
        if (rangeCount == 10) {
            // f 顶点/UV/法线 顶点/UV/法线 顶点/UV/法线
            uint32_t vertexIndex1 = [[line substringWithRange: [result rangeAtIndex:1]] intValue] - 1;
            uint32_t vertexIndex2 = [[line substringWithRange: [result rangeAtIndex:4]] intValue] - 1;
            uint32_t vertexIndex3 = [[line substringWithRange: [result rangeAtIndex:7]] intValue] - 1;
            [self.positionIndexData appendBytes:(void *)(&vertexIndex1) length:sizeof(uint32_t)];
            [self.positionIndexData appendBytes:(void *)(&vertexIndex2) length:sizeof(uint32_t)];
            [self.positionIndexData appendBytes:(void *)(&vertexIndex3) length:sizeof(uint32_t)];
            
            uint32_t uvIndex1 = [[line substringWithRange: [result rangeAtIndex:2]] intValue] - 1;
            uint32_t uvIndex2 = [[line substringWithRange: [result rangeAtIndex:5]] intValue] - 1;
            uint32_t uvIndex3 = [[line substringWithRange: [result rangeAtIndex:8]] intValue] - 1;
            [self.uvIndexData appendBytes:(void *)(&uvIndex1) length:sizeof(uint32_t)];
            [self.uvIndexData appendBytes:(void *)(&uvIndex2) length:sizeof(uint32_t)];
            [self.uvIndexData appendBytes:(void *)(&uvIndex3) length:sizeof(uint32_t)];
            
            uint32_t normalIndex1 = [[line substringWithRange: [result rangeAtIndex:3]] intValue] - 1;
            uint32_t normalIndex2 = [[line substringWithRange: [result rangeAtIndex:6]] intValue] - 1;
            uint32_t normalIndex3 = [[line substringWithRange: [result rangeAtIndex:9]] intValue] - 1;
            [self.normalIndexData appendBytes:(void *)(&normalIndex1) length:sizeof(uint32_t)];
            [self.normalIndexData appendBytes:(void *)(&normalIndex2) length:sizeof(uint32_t)];
            [self.normalIndexData appendBytes:(void *)(&normalIndex3) length:sizeof(uint32_t)];
        }
    }
}

- (SenceVertex *)decompressToVertexArray {
    NSInteger vertexCount = self.positionIndexData.length / sizeof(uint32_t);
    
    SenceVertex *vertex = malloc(sizeof(SenceVertex) * vertexCount);
    for (int i = 0; i < vertexCount; ++i) {
        // 顶点数据
        int positionIndex = 0;
        [self.positionIndexData getBytes:&positionIndex range:NSMakeRange(i * sizeof(uint32_t), sizeof(uint32_t))];
        
        float positionX = 0;
        float positionY = 0;
        float positionZ = 0;
        [self.positionData getBytes:&positionX range:NSMakeRange((positionIndex * 3 + 0) * sizeof(float), sizeof(float))];
        [self.positionData getBytes:&positionY range:NSMakeRange((positionIndex * 3 + 1) * sizeof(float), sizeof(float))];
        [self.positionData getBytes:&positionZ range:NSMakeRange((positionIndex * 3 + 2) * sizeof(float), sizeof(float))];
        
        // 法线数据
        int normalIndex = 0;
        [self.normalIndexData getBytes:&normalIndex range:NSMakeRange(i * sizeof(uint32_t), sizeof(uint32_t))];

        float normalX = 0;
        float normalY = 0;
        float normalZ = 0;
        [self.normalData getBytes:&normalX range:NSMakeRange((normalIndex * 3 + 0) * sizeof(float), sizeof(float))];
        [self.normalData getBytes:&normalY range:NSMakeRange((normalIndex * 3 + 1) * sizeof(float), sizeof(float))];
        [self.normalData getBytes:&normalZ range:NSMakeRange((normalIndex * 3 + 2) * sizeof(float), sizeof(float))];
        
        // 纹理坐标数据
//        int uvIndex = 0;
//        [self.uvIndexData getBytes:&uvIndex range:NSMakeRange(i * sizeof(uint32_t), sizeof(uint32_t))];
//
//        float u = 0;
//        float v = 0;
//        [self.uvData getBytes:&u range:NSMakeRange((uvIndex * 2 + 0) * sizeof(float), sizeof(float))];
//        [self.uvData getBytes:&v range:NSMakeRange((uvIndex * 2 + 1) * sizeof(float), sizeof(float))];
                
        vertex[i] = (SenceVertex){{positionX, positionY, positionZ}, {0, 0}, {normalX, normalY, normalZ}};
    }
    return vertex;
}

@end

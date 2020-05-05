//
//  Filter.h
//  testMetalFilterChain
//
//  Created by Lyman Li on 2020/5/5.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#import <MetalKit/MetalKit.h>

typedef struct {
    vector_float4 position;
    vector_float4 texCoords;
} Vertex;

@interface Filter : NSObject

- (id <MTLTexture>)applyEffectWithTexture:(id <MTLTexture>)texture;

@end

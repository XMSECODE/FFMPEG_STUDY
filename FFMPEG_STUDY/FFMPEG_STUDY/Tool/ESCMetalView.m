#import "ESCMetalView.h"
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

// Vertex struct
typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex;

@interface ESCMetalView ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineRGBA;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineYUV;
@property (nonatomic, strong) id<MTLTexture> textureRGBA;
@property (nonatomic, strong) id<MTLTexture> textureY;  // for YUV
@property (nonatomic, strong) id<MTLTexture> textureU;
@property (nonatomic, strong) id<MTLTexture> textureV;
@property (nonatomic, assign) NSInteger imgWidth;
@property (nonatomic, assign) NSInteger imgHeight;

@property(nonatomic,strong)dispatch_queue_t metal_Queue;


@end

@implementation ESCMetalView

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupMetal];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupMetal];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.metalLayer.drawableSize = self.bounds.size;
}

- (void)destroy {
    self.textureRGBA = nil;
    self.textureY = nil;
    self.textureU = nil;
    self.textureV = nil;
}

- (void)setupMetal {
    self.metal_Queue = dispatch_queue_create("metal_queue", DISPATCH_QUEUE_SERIAL);

    
    
    self.device = MTLCreateSystemDefaultDevice();
    self.metalLayer = (CAMetalLayer *)self.layer;
    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = YES;
    self.commandQueue = [self.device newCommandQueue];
    // 编译 shader
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"ESCMetalShaders" ofType:@"metallib"];
    if (shaderPath) {
        NSData *libData = [NSData dataWithContentsOfFile:shaderPath];
        
        dispatch_data_t dispatchData = dispatch_data_create(libData.bytes, libData.length, dispatch_get_main_queue(), ^{
            // Cleanup block (optional)
        });

        self.defaultLibrary = [self.device newLibraryWithData:dispatchData error:nil];
    } else {
        self.defaultLibrary = [self.device newDefaultLibrary];
    }
    // Pipeline for RGBA/RGB
    {
        id<MTLFunction> vertexFunc = [self.defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragFunc   = [self.defaultLibrary newFunctionWithName:@"fragmentShaderRGBA"];
        MTLRenderPipelineDescriptor *pipelineDesc = [MTLRenderPipelineDescriptor new];
        pipelineDesc.vertexFunction = vertexFunc;
        pipelineDesc.fragmentFunction = fragFunc;
        pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.pipelineRGBA = [self.device newRenderPipelineStateWithDescriptor:pipelineDesc error:nil];
    }
    // Pipeline for YUV420P
    {
        id<MTLFunction> vertexFunc = [self.defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragFunc   = [self.defaultLibrary newFunctionWithName:@"fragmentShaderYUV420"];
        MTLRenderPipelineDescriptor *pipelineDesc = [MTLRenderPipelineDescriptor new];
        pipelineDesc.vertexFunction = vertexFunc;
        pipelineDesc.fragmentFunction = fragFunc;
        pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.pipelineYUV = [self.device newRenderPipelineStateWithDescriptor:pipelineDesc error:nil];
    }
    self.type = ESCVideoDataTypeRGBA;
    self.showType = ESCOpenGLESViewShowTypeAspectFit;
}

// MARK: - Draw Methods

- (void)redraw {
    dispatch_async(self.metal_Queue, ^{
        
        
        if (!self.device || !self.commandQueue) return;
        CGSize drawableSize = self.metalLayer.drawableSize;
        if (drawableSize.width <=0 || drawableSize.height <= 0) return;
        id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
        if (!drawable) return;
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        MTLRenderPassDescriptor *desc = [MTLRenderPassDescriptor renderPassDescriptor];
        desc.colorAttachments[0].texture = drawable.texture;
        desc.colorAttachments[0].loadAction = MTLLoadActionClear;
        desc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
        desc.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];
        
        Vertex quadVertices[4];
        float quadW = self.imgWidth, quadH = self.imgHeight;
        float viewW = drawableSize.width, viewH = drawableSize.height;
        float sx=1, sy=1;
        //    float dx=0, dy=0;
        if (self.showType == ESCOpenGLESViewShowTypeAspectFit && quadW > 0 && quadH > 0) {
            float scaleW = viewW / quadW, scaleH = viewH / quadH;
            float scale = MIN(scaleW, scaleH);
            sx = (quadW * scale) / viewW;
            sy = (quadH * scale) / viewH;
        }
        // (NDC, texcoord)
        quadVertices[0] = (Vertex){ {-sx, -sy}, { 0, 1} };
        quadVertices[1] = (Vertex){ { sx, -sy}, { 1, 1} };
        quadVertices[2] = (Vertex){ {-sx,  sy}, { 0, 0} };
        quadVertices[3] = (Vertex){ { sx,  sy}, { 1, 0} };
        [encoder setVertexBytes:quadVertices length:sizeof(quadVertices) atIndex:0];
        
        if (self.type == ESCVideoDataTypeRGBA || self.type == ESCVideoDataTypeRGB) {
            [encoder setRenderPipelineState:self.pipelineRGBA];
            if (self.textureRGBA) [encoder setFragmentTexture:self.textureRGBA atIndex:0];
        } else if (self.type == ESCVideoDataTypeYUV420) {
            [encoder setRenderPipelineState:self.pipelineYUV];
            if (self.textureY) [encoder setFragmentTexture:self.textureY atIndex:0];
            if (self.textureU) [encoder setFragmentTexture:self.textureU atIndex:1];
            if (self.textureV) [encoder setFragmentTexture:self.textureV atIndex:2];
        }
        [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [encoder endEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            [commandBuffer presentDrawable:drawable];
            [commandBuffer commit];
        });
    });
}

// MARK: - Data Loading

- (void)loadImage:(UIImage *)image {
    CGImageRef cgImg = image.CGImage;
    size_t width = CGImageGetWidth(cgImg);
    size_t height = CGImageGetHeight(cgImg);
    self.imgWidth = width;
    self.imgHeight = height;
    // RGBA pixels
    size_t bytesPerRow = width * 4;
    uint8_t *pixels = calloc(1, bytesPerRow * height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), cgImg);
    [self loadRGBData:pixels length:(int)(bytesPerRow*height) width:(int)width height:(int)height];
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
}

- (void)loadRGBData:(void *)data length:(NSInteger)length width:(NSInteger)width height:(NSInteger)height {
    self.imgWidth = width;
    self.imgHeight = height;
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: (self.type==ESCVideoDataTypeRGBA? MTLPixelFormatRGBA8Unorm: MTLPixelFormatRGBA8Unorm)
                                                                                  width:width
                                                                                 height:height
                                                                              mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead;
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:desc];
    NSUInteger bytesPerRow = width * (self.type==ESCVideoDataTypeRGBA? 4:3);
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:data bytesPerRow:bytesPerRow];
    self.textureRGBA = texture;

    [self redraw];
}

- (void)loadYUV420PDataWithYData:(NSData *)yData uData:(NSData *)uData vData:(NSData *)vData width:(NSInteger)width height:(NSInteger)height {
    dispatch_async(self.metal_Queue, ^{
        
        self.imgWidth = width;
        self.imgHeight = height;
        // Y
        MTLTextureDescriptor *descY = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                         width:width height:height mipmapped:NO];
        descY.usage = MTLTextureUsageShaderRead;
        id<MTLTexture> ytex = [self.device newTextureWithDescriptor:descY];
        [ytex replaceRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0 withBytes:yData.bytes bytesPerRow:width];
        // U,V (UV 宽高是原来的一半)
        MTLTextureDescriptor *descU = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                         width:width/2 height:height/2 mipmapped:NO];
        descU.usage = MTLTextureUsageShaderRead;
        id<MTLTexture> utex = [self.device newTextureWithDescriptor:descU];
        [utex replaceRegion:MTLRegionMake2D(0,0,width/2,height/2) mipmapLevel:0 withBytes:uData.bytes bytesPerRow:width/2];
        id<MTLTexture> vtex = [self.device newTextureWithDescriptor:descU]; // same desc
        [vtex replaceRegion:MTLRegionMake2D(0,0,width/2,height/2) mipmapLevel:0 withBytes:vData.bytes bytesPerRow:width/2];
        self.textureY = ytex;
        self.textureU = utex;
        self.textureV = vtex;

        [self redraw];
    });
}

- (void)setType:(ESCVideoDataType)type {
    _type = type;

    [self redraw];
}

- (void)setShowType:(ESCOpenGLESViewShowType)showType {
    _showType = showType;

    [self redraw];
}

@end

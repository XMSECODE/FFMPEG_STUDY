#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "ESCType.h"



@interface ESCMetalView : UIView

@property(nonatomic,assign) ESCVideoDataType type;
@property(nonatomic,assign) ESCOpenGLESViewShowType showType;

- (void)loadImage:(UIImage *)image;
- (void)loadRGBData:(void *)data length:(NSInteger)length width:(NSInteger)width height:(NSInteger)height;
- (void)loadYUV420PDataWithYData:(NSData *)yData uData:(NSData *)uData vData:(NSData *)vData width:(NSInteger)width height:(NSInteger)height;
- (void)destroy;

@end

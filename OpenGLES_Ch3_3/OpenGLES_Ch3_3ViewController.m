//
//  ViewController.m
//  OpenGLES_Ch3_3
//

#import "OpenGLES_Ch3_3ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"

#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)
#define RANDOM_FLOAT_BETWEEN(x, y) (((float) rand() / RAND_MAX) * (y - x) + x)

@interface GLKEffectPropertyTexture (AGLKAdditions)

- (void)aglkSetParameter:(GLenum)parameterID
                   value:(GLint)value;

@end

@implementation GLKEffectPropertyTexture (AGLKAdditions)

- (void)aglkSetParameter:(GLenum)parameterID
                   value:(GLint)value;
{
    glBindTexture(self.target, self.name);
    
    glTexParameteri(
                    self.target,
                    parameterID,
                    value);
}

@end

typedef struct {
    GLKVector3  positionCoords;
    GLKVector2  textureCoords;
} SceneVertex;


@interface OpenGLES_Ch3_3ViewController ()

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexBuffer;
@property (assign, nonatomic) GLfloat sCoordinateOffset;
@property (assign, nonatomic) GLfloat step;
@end


@implementation OpenGLES_Ch3_3ViewController

static SceneVertex vertices[361];
//{
//    {{-0.5f, -0.5f, 0.0f}}, // lower left corner
//    {{ 0.5f, -0.5f, 0.0f}}, // lower right corner
//    {{-0.5f,  0.5f, 0.0f}}, // upper left corner
//};

- (void)updateAnimatedVertexPositions
{
    if (vertices[0].positionCoords.y> 1) {
        self.step = -0.02;
    }
    
    if (vertices[0].positionCoords.y < -1) {
        self.step = 0.02;
    }
    
    vertices[0].positionCoords.y += self.step;
 
    for (int i = 1; i < 361; i += 1) {
        vertices[i].positionCoords.y += self.step;
    }
}

- (void)update
{
    [self updateAnimatedVertexPositions];
    [self.vertexBuffer reinitWithAttribStride:sizeof(SceneVertex)
                             numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)
                                        bytes:vertices];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 24;
    self.step = 0.02;
    
    GLKView *view = (GLKView *)self.view;
    view.context = [[AGLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    
    self.baseEffect = [GLKBaseEffect new];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    ((AGLKContext *)view.context).clearColor = GLKVector4Make(1, 1, 1, 1.0f);
    
    float scale = [UIScreen mainScreen].bounds.size.width / [UIScreen mainScreen].bounds.size.height;
    for (int i = 0; i < 361; i += 1) {
        float X = sin(DEGREES_TO_RADIANS(i));
        float Y = cos(DEGREES_TO_RADIANS(i));
        SceneVertex tmp = {{X * 0.2, Y * 0.2, 0}, {(X + 1) / 2, 1 - (Y + 1) / 2}};
        vertices[i] = tmp;
    }
    
    // Create vertex buffer containing vertices to draw
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                         initWithAttribStride:sizeof(SceneVertex)
                         numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)
                         bytes:vertices
                         usage:GL_DYNAMIC_DRAW];
    // Setup texture
    CGImageRef imageRef = [[UIImage imageNamed:@"boy-512.png"] CGImage];
    GLKTextureInfo *textureInfo = [GLKTextureLoader
                                   textureWithCGImage:imageRef
                                   options:nil
                                   error:NULL];
    
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.baseEffect prepareToDraw];
    
    // Clear back frame buffer (erase previous drawing)
    [(AGLKContext *)view.context clear:GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT];
    
    
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                           numberOfCoordinates:3
                                  attribOffset:offsetof(SceneVertex, positionCoords)
                                  shouldEnable:YES];
    
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                           numberOfCoordinates:2
                                  attribOffset:offsetof(SceneVertex, textureCoords)
                                  shouldEnable:YES];
    
    [self.vertexBuffer drawArrayWithMode:GL_TRIANGLE_FAN
                        startVertexIndex:0
                        numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Make the view's context current
    GLKView *view = (GLKView *)self.view;
    [AGLKContext setCurrentContext:view.context];
    
    self.vertexBuffer = nil;
    ((GLKView *)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
}

@end

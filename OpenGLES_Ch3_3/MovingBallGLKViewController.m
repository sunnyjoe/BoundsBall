//
//  ViewController.m
//  OpenGLES_Ch3_3
//

#import "MovingBallGLKViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"
#import <CoreMotion/CoreMotion.h>

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


@interface MovingBallGLKViewController (){
    CMAcceleration ar;
    float fallT;
    GLfloat stepX;
    GLfloat stepY;
}

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexBuffer;
@property (assign, nonatomic) GLfloat sCoordinateOffset;
@property (strong, nonatomic) CMMotionManager *mManager;
@end


@implementation MovingBallGLKViewController

static SceneVertex vertices[361];
//{
//    {{-0.5f, -0.5f, 0.0f}}, // lower left corner
//    {{ 0.5f, -0.5f, 0.0f}}, // lower right corner
//    {{-0.5f,  0.5f, 0.0f}}, // upper left corner
//};

- (void)updateAnimatedVertexPositions
{
    fallT ++;
    float timeDur = fallT / self.preferredFramesPerSecond;
    
    if (ar.y < 0) {
        stepY = -0.2 * 0.5 * 9.8 * (1 - ABS(ar.z)) * timeDur * timeDur;
        if (vertices[180].positionCoords.y <= -1) {
            stepY = -1 - vertices[180].positionCoords.y;
            fallT = 0;
        }
    }else{
        stepY = 0.2 * 0.5 * 9.8 * (1 - ABS(ar.z))  * timeDur * timeDur;
        if (vertices[0].positionCoords.y >= 1) {
            stepY = 1 - vertices[0].positionCoords.y;
            fallT = 0;
        }
    }
    
    if (ar.x > 0) {
        stepX = 0.2 * 0.5 * 9.8 * ABS(ar.x) * timeDur * timeDur;
        if (vertices[90].positionCoords.x >= 1) {
            stepX = 1 - vertices[90].positionCoords.x;
            fallT = 0;
        }
    }else{
        stepX = -0.2 * 0.5 * 9.8 * ABS(ar.x) * timeDur * timeDur;
        if (vertices[270].positionCoords.x <= -1) {
            stepX = -1 - vertices[270].positionCoords.x;
            fallT = 0;
        }
    }
    
    for (int i = 0; i < 361; i += 1) {
        vertices[i].positionCoords.x += stepX;
        vertices[i].positionCoords.y += stepY;
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
    self.mManager = [CMMotionManager new];
    [self.mManager startAccelerometerUpdates];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateAcceleraoMeter) userInfo:nil repeats:true];
    
    self.preferredFramesPerSecond = 24;
    
    GLKView *view = (GLKView *)self.view;
    view.context = [[AGLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    
    self.baseEffect = [GLKBaseEffect new];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    ((AGLKContext *)view.context).clearColor = GLKVector4Make(1, 1, 1, 1.0f);
    
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

- (void)updateAcceleraoMeter{
    CMAccelerometerData *data = self.mManager.accelerometerData;
    ar = data.acceleration;
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

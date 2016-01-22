//
//  OpenGLES_Ch5_1ViewController.m
//  OpenGLES_Ch5_1
//

#import "SphereGLKViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"
#import "sphere.h"             // Vertex data for a sphere


@interface SphereGLKViewController ()

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexPositionBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexNormalBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexTextureCoordBuffer;
@property (strong, nonatomic) GLKTextureInfo *earthTextureInfo;
@property (strong, nonatomic) GLKTextureInfo *moonTextureInfo;
@property (nonatomic) GLKMatrixStackRef modelviewMatrixStack;
@property (nonatomic) GLfloat earthRotationAngleDegrees;
@property (nonatomic) GLfloat moonRotationAngleDegrees;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;


@end

@implementation SphereGLKViewController

@synthesize baseEffect;
@synthesize vertexPositionBuffer;
@synthesize vertexNormalBuffer;
@synthesize vertexTextureCoordBuffer;
@synthesize earthTextureInfo;
@synthesize moonTextureInfo;
@synthesize modelviewMatrixStack;
@synthesize earthRotationAngleDegrees;
@synthesize moonRotationAngleDegrees;


static const GLfloat  SceneDaysPerMoonOrbit = 28.0f;
static const GLfloat  SceneMoonRadiusFractionOfEarth = 0.25;
static const GLfloat  SceneMoonDistanceFromEarth = 1;

- (IBAction)closeBtnDidTapped:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)configureLight
{
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, // Red
                                                         1.0f, // Green
                                                         1.0f, // Blue
                                                         1.0f);// Alpha
    self.baseEffect.light0.position = GLKVector4Make(1.0f,
                                                     0.0f,
                                                     0.8f,
                                                     0.0f);
    self.baseEffect.light0.ambientColor = GLKVector4Make(0.2f, // Red
                                                         0.2f, // Green
                                                         0.2f, // Blue
                                                         1.0f);// Alpha
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.preferredFramesPerSecond = 24;
    
    GLKView *view = (GLKView *)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.context = [[AGLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    self.baseEffect = [GLKBaseEffect new];

    [self configureLight];
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho( -1.0 * 4.0 / 3.0, 1.0 * 4.0 / 3.0, -1.0, 1.0, 1.0, 120.0);
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0);
    
    self.modelviewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    GLKMatrixStackLoadMatrix4(self.modelviewMatrixStack, self.baseEffect.transform.modelviewMatrix);
    self.moonRotationAngleDegrees = -20.0f;

    ((AGLKContext *)view.context).clearColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);// Alpha
    
    // Create vertex buffers containing vertices to draw
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                 initWithAttribStride:(3 * sizeof(GLfloat))
                                 numberOfVertices:sizeof(sphereVerts) / (3 * sizeof(GLfloat))
                                 bytes:sphereVerts
                                 usage:GL_STATIC_DRAW];
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                               initWithAttribStride:(3 * sizeof(GLfloat))
                               numberOfVertices:sizeof(sphereNormals) / (3 * sizeof(GLfloat))
                               bytes:sphereNormals
                               usage:GL_STATIC_DRAW];
    self.vertexTextureCoordBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                     initWithAttribStride:(2 * sizeof(GLfloat))
                                     numberOfVertices:sizeof(sphereTexCoords) / (2 * sizeof(GLfloat))
                                     bytes:sphereTexCoords
                                     usage:GL_STATIC_DRAW];
    
    // Setup Earth texture
    CGImageRef earthImageRef =
    [[UIImage imageNamed:@"Earth512x256.jpg"] CGImage];
    
    earthTextureInfo = [GLKTextureLoader
                        textureWithCGImage:earthImageRef
                        options:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES],
                                 GLKTextureLoaderOriginBottomLeft, nil]
                        error:NULL];
    
    // Setup Moon texture
    CGImageRef moonImageRef =
    [[UIImage imageNamed:@"Moon256x128.png"] CGImage];
    
    moonTextureInfo = [GLKTextureLoader
                       textureWithCGImage:moonImageRef
                       options:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES],
                                GLKTextureLoaderOriginBottomLeft, nil]
                       error:NULL];
}

- (void)drawEarth
{
    self.baseEffect.texture2d0.name = earthTextureInfo.name;
    self.baseEffect.texture2d0.target = earthTextureInfo.target;
    
    GLKMatrixStackPush(self.modelviewMatrixStack);

    GLKMatrixStackRotate(self.modelviewMatrixStack, GLKMathDegreesToRadians(earthRotationAngleDegrees),
                         0.0, 1.0, 0.0);
    
    GLfloat aspectRatio =  (GLfloat)((GLKView *)self.view).drawableWidth / (GLfloat)((GLKView *)self.view).drawableHeight;
    GLKMatrixStackScale(self.modelviewMatrixStack, 1.0f, aspectRatio * 0.7, 1.0f);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    
    [AGLKVertexAttribArrayBuffer
     drawPreparedArraysWithMode:GL_TRIANGLES
     startVertexIndex:0
     numberOfVertices:sphereNumVerts];
    
    GLKMatrixStackPop(self.modelviewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
}

- (void)drawMoon
{
    self.baseEffect.texture2d0.name = moonTextureInfo.name;
    self.baseEffect.texture2d0.target = moonTextureInfo.target;
    
    GLKMatrixStackPush(self.modelviewMatrixStack);
    
    GLKMatrixStackRotate(self.modelviewMatrixStack, GLKMathDegreesToRadians(moonRotationAngleDegrees),
                         0.0, 1.0, 0.0);
    GLKMatrixStackTranslate(self.modelviewMatrixStack, 0.0, 0.0, SceneMoonDistanceFromEarth);
    GLKMatrixStackScale(self.modelviewMatrixStack, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);
    GLKMatrixStackRotate(self.modelviewMatrixStack, GLKMathDegreesToRadians(moonRotationAngleDegrees),
                         0.0, 1.0, 0.0);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    [AGLKVertexAttribArrayBuffer
     drawPreparedArraysWithMode:GL_TRIANGLES
     startVertexIndex:0
     numberOfVertices:sphereNumVerts];
    
    GLKMatrixStackPop(self.modelviewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix =
    GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    self.earthRotationAngleDegrees += 360.0f / 60.0f;
    self.moonRotationAngleDegrees += (360.0f / 60.0f) / SceneDaysPerMoonOrbit;
    
    [(AGLKContext *)view.context clear:GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT];
    
    [self.vertexPositionBuffer
     prepareToDrawWithAttrib:GLKVertexAttribPosition
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexNormalBuffer
     prepareToDrawWithAttrib:GLKVertexAttribNormal
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexTextureCoordBuffer
     prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
     numberOfCoordinates:2
     attribOffset:0
     shouldEnable:YES];
    
    [self drawEarth];
    [self drawMoon];
    
    [(AGLKContext *)view.context enable:GL_DEPTH_TEST];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    GLKView *view = (GLKView *)self.view;
    [AGLKContext setCurrentContext:view.context];
    
    self.vertexPositionBuffer = nil;
    self.vertexNormalBuffer = nil;
    self.vertexTextureCoordBuffer = nil;
    
    ((GLKView *)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
    
    CFRelease(self.modelviewMatrixStack);
    self.modelviewMatrixStack = NULL;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown &&
            interfaceOrientation !=  UIInterfaceOrientationPortrait);
}


- (IBAction)takeShouldUsePerspectiveFrom:(UISwitch *)aControl;
{
    GLfloat aspectRatio = (float)((GLKView *)self.view).drawableWidth / (float)((GLKView *)self.view).drawableHeight;
    
    if([aControl isOn])
    {
        self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(
                              -1.0 * aspectRatio, 
                              1.0 * aspectRatio, 
                              -1.0, 
                              1.0, 
                              1.0,
                              120.0);  
    }
    else
    {
        self.baseEffect.transform.projectionMatrix =  GLKMatrix4MakeOrtho(
                            -1.0 * aspectRatio, 
                            1.0 * aspectRatio, 
                            -1.0, 
                            1.0, 
                            1.0,
                            120.0);  
    }
}

@end


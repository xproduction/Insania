/*==============================================================================
 Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/

// Subclassed from AR_EAGLView
#import "EAGLView.h"
#import "GlObject.h"
#import "Texture.h"

#import <QCAR/Renderer.h>
#import <QCAR/VideoBackgroundConfig.h>
#import "QCARutils.h"

#ifndef USE_OPENGL1
#import "ShaderUtils.h"
#endif

namespace {
    // Teapot texture filenames
    const char* textureFilenames[] = {
        "blackdrum.png",
        "poly.png",
        "klima.png",
        "tudy.png"
    };

    // Model scale factor
    const float kObjectScale = 3.0f;
}

BOOL render = NO;
BOOL screenshoot = NO;

@implementation EAGLView

- (void) setRender:(BOOL) inRender {
    render = inRender;
}

- (void) setScreenshot:(BOOL) inScreenshot {
    screenshoot = inScreenshot;
}

- (BOOL) getRender {
    return render;
}

- (BOOL) getScreenshot {
    return screenshoot;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
	if (self)
    {
        // create list of textures we want loading - ARViewController will do this for us
        int nTextures = sizeof(textureFilenames) / sizeof(textureFilenames[0]);
        for (int i = 0; i < nTextures; ++i)
            [textureList addObject: [NSString stringWithUTF8String:textureFilenames[i]]];
    }
    
    return self;
}

- (void) setup3dObjects
{
    // build the array of objects we want drawn and their texture
    // in this example we have 3 targets and require 3 models
    // but using the same underlying 3D model of a teapot, differentiated
    // by using a different texture for each
    
    for (int i=0; i < [textures count]; i++)
    {
        Object3D *obj3D = [[Object3D alloc] init];

        obj3D.numVertices = NUM_OBJECT_VERTEX;
        obj3D.vertices = vertices;
        obj3D.normals = normals;
        obj3D.texCoords = texCoords;
        
        obj3D.numIndices = NUM_OBJECT_INDEX;
        obj3D.indices = indices;
        
        obj3D.texture = [textures objectAtIndex:i];

        [objects3D addObject:obj3D];
        [obj3D release];
    }
    
}


// called after QCAR is initialised but before the camera starts
- (void) postInitQCAR
{
    // Here we could make a QCAR::setHint call to set the maximum
    // number of simultaneous targets                
    // QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 2);
}

// modify renderFrameQCAR here if you want a different 3D rendering model
////////////////////////////////////////////////////////////////////////////////
// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method on a single background thread ***
- (void)renderFrameQCAR
{
    if(screenshoot)
        return;
    
    render = YES;
    
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    //NSLog(@"active trackables: %d", state.getNumActiveTrackables());
    
    if (QCAR::GL_11 & qUtils.QCARFlags) {
        glEnable(GL_TEXTURE_2D);
        glDisable(GL_LIGHTING);
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models. 
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        const QCAR::Trackable& trackable = result->getTrackable();
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        
        // Choose the texture based on the target name
        int targetIndex = 0; // "stones"
        if (!strcmp(trackable.getName(), "coverFront"))
            targetIndex = 1;
        else if (!strcmp(trackable.getName(), "book"))
            targetIndex = 2;
        else if (!strcmp(trackable.getName(), "bookFront"))
            targetIndex = 3;
        
        Object3D *obj3D = [objects3D objectAtIndex:targetIndex];
        
        // Render using the appropriate version of OpenGL
        if (QCAR::GL_11 & qUtils.QCARFlags) {
            // Load the projection matrix
            glMatrixMode(GL_PROJECTION);
            glLoadMatrixf(qUtils.projectionMatrix.data);
            
            // Load the model-view matrix
            glMatrixMode(GL_MODELVIEW);
            glLoadMatrixf(modelViewMatrix.data);
            glTranslatef(0.0f, 0.0f, -kObjectScale);
            glScalef(kObjectScale, kObjectScale, kObjectScale);
            
            // Draw object
            glBindTexture(GL_TEXTURE_2D, [obj3D.texture textureID]);
            glTexCoordPointer(2, GL_FLOAT, 0, (const GLvoid*)obj3D.texCoords);
            glVertexPointer(3, GL_FLOAT, 0, (const GLvoid*)obj3D.vertices);
            glNormalPointer(GL_FLOAT, 0, (const GLvoid*)obj3D.normals);
            glDrawElements(GL_TRIANGLE_STRIP, obj3D.numIndices, GL_UNSIGNED_SHORT, (const GLvoid*)obj3D.indices);
        }
#ifndef USE_OPENGL1
        else {
            // OpenGL 2
            QCAR::Matrix44F modelViewProjection;
            
            ShaderUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScale, &modelViewMatrix.data[0]);
            ShaderUtils::scalePoseMatrix(kObjectScale, kObjectScale, kObjectScale, &modelViewMatrix.data[0]);
            ShaderUtils::multiplyMatrix(&qUtils.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);

            glUseProgram(shaderProgramID);
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)obj3D.vertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)obj3D.normals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)obj3D.texCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            glActiveTexture(GL_TEXTURE0);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glBindTexture(GL_TEXTURE_2D, [obj3D.texture textureID]);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
            glUniform1i(texSampler2DHandle, 0);
            glDrawElements(GL_TRIANGLE_STRIP, obj3D.numIndices, GL_UNSIGNED_SHORT, (const GLvoid*)obj3D.indices);
            
            ShaderUtils::checkGlError("EAGLView renderFrameQCAR");
        }
#endif
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    if (QCAR::GL_11 & qUtils.QCARFlags) {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
#ifndef USE_OPENGL1
    else {
        glDisableVertexAttribArray(vertexHandle);
        glDisableVertexAttribArray(normalHandle);
        glDisableVertexAttribArray(textureCoordHandle);
    }
#endif
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
    render = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end

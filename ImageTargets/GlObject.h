/*==============================================================================
 Copyright (c) 2010-2013 QUALCOMM Austria Research Center GmbH.
 All Rights Reserved.
 Qualcomm Confidential and Proprietary
 ==============================================================================*/


#ifndef _GL_OBJECT_H
#define _GL_OBJECT_H

#define NUM_OBJECT_VERTEX 4
#define NUM_OBJECT_INDEX 4

const float size = 105.0f;
const float distance = 0.0f;
const float texSize = 1.0f;

//teapot.h
//teapotVertices, teapotTexCoords, teapotNormals, teapotIndices
static const float vertices[NUM_OBJECT_VERTEX * 3] =
{
    -size, -size, distance,
    size, -size, distance,
    size, size, distance,
    -size, size, distance,
};

static const float texCoords[NUM_OBJECT_VERTEX * 2] =
{
    texSize, 0,
    0, 0,
    0, texSize,
    texSize, texSize,
};

static const float normals[NUM_OBJECT_VERTEX * 3] =
{
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,
    0.0, 0.0, -1.0,
};

static const unsigned short indices[NUM_OBJECT_INDEX] =
{
    0, 1, 3, 2
};

#endif // _GL_OBJECT_H_

/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CAMediaTimingFunction.h>

//void _CAMediaTimingFunctionGetControlPointAtIndex(CAMediaTimingFunction *function, size_t idx, float* ptr);
float _CAMediaTimingFunctionApply(CAMediaTimingFunction *function, float t);
//float _CAMTFSolveCubicPolynomialBetweenValues(CAMediaTimingFunction *function, float x);
//float _CASolveCubicPolynomialBetweenValues(float t0, float t1, float a, float b, float c, float d);
//float _CAMTFSolveCubicPolynomialBetweenValues(float t0, float t1, float a, float b, float c, float d);
/*
static inline float cubed(float value)
{
    return value*value*value;
}

static inline float squared(float value)
{
    return value*value;
}
*/

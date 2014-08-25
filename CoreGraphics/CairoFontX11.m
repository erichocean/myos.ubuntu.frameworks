/** <title>CairoFontX11</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006
   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: January, 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

// FIXME: hack, fix the build system
#ifndef __MINGW__

#import <Foundation/NSString.h>
#include "CoreGraphics/CGBase.h"
#include "CoreGraphics/CGDataProvider.h"
#include "CoreGraphics/CGFont.h"
#include <stdlib.h>
#include <string.h>

#import "CairoFontX11.h"
#import "CairoFontX11-private.h"


//
// Note on CGFont: we really need  David Turner's cairo-ft rewrite,
// which is on the roadmap for cairo 1.12.
//
// The current cairo_ft_scaled_font_lock_face function is almost useless.
// With it, we can only (safely) look at immutable parts of the FT_Face.
//
@implementation CairoFontX11

- (CFStringRef) copyFullName;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CFStringRef result = NULL;
  
  if (ft_face) {
    const int FULL_NAME = 4;
    FT_SfntName nameStruct;
    if (0 == FT_Get_Sfnt_Name(ft_face, FULL_NAME, &nameStruct))
    {
      if (nameStruct.platform_id == TT_PLATFORM_APPLE_UNICODE)
      {
        result = [[NSString alloc] initWithBytes: nameStruct.string length: nameStruct.string_len encoding: NSUTF16BigEndianStringEncoding];
      }
      else if (nameStruct.platform_id == TT_PLATFORM_MACINTOSH &&
               nameStruct.encoding_id == TT_MAC_ID_ROMAN)
      {
        result = [[NSString alloc] initWithBytes: nameStruct.string length: nameStruct.string_len encoding: NSMacOSRomanStringEncoding];
      }
      else if (nameStruct.platform_id == TT_PLATFORM_MICROSOFT &&
               nameStruct.encoding_id == TT_MS_ID_UNICODE_CS)
      {
        result = [[NSString alloc] initWithBytes: nameStruct.string length: nameStruct.string_len encoding: NSUTF16BigEndianStringEncoding];
      }
    }
    
    if (NULL != ft_face->family_name) {
      result = [[NSString alloc] initWithUTF8String: ft_face->family_name];
    }
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CFStringRef) copyGlyphNameForGlyph: (CGGlyph)glyph;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CFStringRef result = NULL;
  
  if (ft_face) {
    char buffer[256];
    FT_Get_Glyph_Name(ft_face, glyph, buffer, 256);
    result = [[NSString alloc] initWithUTF8String: buffer];
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CFStringRef) copyPostScriptName;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CFStringRef result = NULL;
  
  if (ft_face) {
    const char *psname = FT_Get_Postscript_Name(ft_face);
    if (NULL != psname) {
      result = [[NSString alloc] initWithUTF8String: psname];
    } 
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);  
  return result;
}

- (CFDataRef) copyTableForTag: (uint32_t)tag;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CFDataRef result = NULL;
  
  if (ft_face) {
    FT_ULong length = 0;
    void *buffer;
    
    if (0 == FT_Load_Sfnt_Table(ft_face, tag, 0, NULL, &length)) {
      buffer = malloc(length);
      if (buffer) {
        if (0 == FT_Load_Sfnt_Table(ft_face, tag, 0, buffer, &length)) {
          result = [[NSData alloc] initWithBytes: buffer length: length];
        }
        free(buffer);
      }
    }
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CFArrayRef) copyTableTags;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CFMutableArrayRef result = [[NSMutableArray alloc] init];
  
  if (ft_face) {
    unsigned int i = 0;
    unsigned long tag, length;

    while (FT_Err_Table_Missing !=
           FT_Sfnt_Table_Info(ft_face, i, &tag, &length))
    {
      // FIXME: see CGFontCopyTableTags reference, the CFArray should contain raw tags and not NSNumbers
      [result addObject: [NSNumber numberWithInt: tag]];
      i++;
    }
  }

  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CFArrayRef) copyVariationAxes;
{
  return NULL;
}

- (CFDictionaryRef) copyVariations;
{
  return NULL;
}

- (CGFontRef) createCopyWithVariations: (CFDictionaryRef)variations;
{
  return NULL;
}

- (CFDataRef) createPostScriptEncoding: (const CGGlyph[])encoding;
{
  return NULL;
}

- (int) ascent;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  int result = ft_face->bbox.yMax;
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (int) capHeight;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sCapHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (int) descent;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  int result = 0;
  
  result = ft_face->bbox.yMax;
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CGRect) fontBBox;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  FT_BBox bbox = ft_face->bbox;
  CGRect result = CGRectMake(
    bbox.xMin,
    bbox.yMin, 
    bbox.xMax - bbox.xMin,
    bbox.yMax - bbox.yMin);
    
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CGGlyph) glyphWithGlyphName: (CFStringRef)glyphName;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CGGlyph result = 0;
  
  const char *name = [glyphName UTF8String];
  result = (CGGlyph)FT_Get_Name_Index(ft_face, (FT_String*)name);
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CGFloat) italicAngle;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  CGFloat result = 0;
  
  TT_Postscript *pstable = (TT_Postscript *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_post);
  if (NULL != pstable) {
    result = pstable->italicAngle;
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (int) leading;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  
  // see http://www.typophile.com/node/13081
  int result =  ft_face->height - ft_face->ascender + 
    ft_face->descender;
    
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (size_t) numberOfGlyphs;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  
  int result = ft_face->num_glyphs;
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (CGFloat) stemV;
{
  return 0;
}

- (int) unitsPerEm;
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  
  int result = ft_face->units_per_EM;
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

- (int) xHeight
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  int result = 0;
  
  TT_OS2 *os2table = (TT_OS2 *)FT_Get_Sfnt_Table(ft_face, ft_sfnt_os2);
  if (NULL != os2table) {
    result = os2table->sxHeight;
  }
  
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return result;
}

+ (CGFontRef) createWithFontName: (CFStringRef)name;
{
  FcPattern *pat;
  cairo_font_face_t *unscaled;
  CairoFontX11 *font = [[CairoFontX11 alloc] init];
  if (!font) return NULL;

  pat = opal_FcPatternCacheLookup([(NSString*)name UTF8String]);
  if(pat) {
    unscaled = cairo_ft_font_face_create_for_pattern(pat);
  } else {
    CGFontRelease(font);
    return NULL;
  }

  // Create a cairo_scaled_font which we just use to access the underlying
  // FT_Face

  cairo_matrix_t ident;
  cairo_matrix_init_identity(&ident);

  cairo_font_options_t *opts = cairo_font_options_create();
  cairo_font_options_set_hint_metrics(opts, CAIRO_HINT_METRICS_OFF);
  cairo_font_options_set_hint_style(opts, CAIRO_HINT_STYLE_NONE);
  
  font->cairofont = cairo_scaled_font_create(unscaled,
    &ident, &ident, opts);
    
  cairo_font_options_destroy(opts);

  font->fullName = [font copyFullName];
  font->postScriptName = [font copyPostScriptName];
  font->ascent = [font ascent];
  font->capHeight = [font capHeight];
  font->descent = [font descent];
  font->fontBBox = [font fontBBox];
  font->italicAngle = [font italicAngle];
  font->leading = [font leading];
  font->numberOfGlyphs = [font numberOfGlyphs];
  font->stemV = [font stemV];
  font->unitsPerEm = [font unitsPerEm];
  font->xHeight = [font xHeight];
  return (CGFontRef)font;
}

+ (CGFontRef) createWithPlatformFont: (void *)platformFontReference;
{
  return NULL;
}

//FIXME: Not threadsafe
- (bool) getGlyphAdvances: (const CGGlyph[])glyphs
                         : (size_t)count
                         : (int[]) advances
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  for (size_t i=0; i<count; i++)
  {
    FT_Load_Glyph(ft_face, glyphs[i], FT_LOAD_NO_SCALE);
    advances[i] = ft_face->glyph->metrics.horiAdvance;
  }
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return true;
}

//FIXME: Not threadsafe
- (bool) getGlyphBBoxes: (const CGGlyph[])glyphs
                       : (size_t)count
                       : (CGRect[])bboxes
{
  FT_Face ft_face = cairo_ft_scaled_font_lock_face(self->cairofont);
  for (size_t i=0; i<count; i++)
  {
    FT_Load_Glyph(ft_face, glyphs[i], FT_LOAD_NO_SCALE);
    FT_Glyph_Metrics m = ft_face->glyph->metrics;
    bboxes[i] = CGRectMake(m.horiBearingX, m.horiBearingY - m.height, m.width, m.height);
  }
  cairo_ft_scaled_font_unlock_face(self->cairofont);
  return true;
}

@end

#endif

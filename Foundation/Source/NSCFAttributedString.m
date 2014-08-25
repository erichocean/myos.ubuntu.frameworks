/* NSCFAttributedString.m
   
   Copyright (C) 2012 MyUIKit.
   
   Written by: Mohamed Abdelsalam
   Date: Novamber, 2012
   
   This file is part of MyUIKit Library.
*/


#import <Foundation/NSString.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSCFType.h>

#import <Foundation/NSException.h>
#import <CoreFoundation/CFAttributedString.h>
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFArray.h>



@interface NSCFAttributedString : NSMutableAttributedString
@end



@implementation NSCFAttributedString
+ (void) load
{
  NSCFInitialize ();
}


- (id)initWithString:(NSString *)aString
{

    CFAttributedStringRef new;
    new = CFAttributedStringCreate (NULL,aString,NULL);
    [self release];
    self = (NSAttributedString*)new;
    return self;

}
- (id)initWithString:(NSString *)aString attributes:(NSDictionary *)attributes
{
    CFAttributedStringRef new;
    new = CFAttributedStringCreate (NULL,aString,attributes);
    [self release];
    self = (NSAttributedString*)new;
    return self;

}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
    CFAttributedStringRef new;
    new = CFAttributedStringCreateCopy (NULL,self);  
    [self release];
    self = (NSAttributedString*)new;
    return self;

}


- (NSString*) string
{
	return (NSString*)CFAttributedStringGetString(self);
}


- (NSUInteger) length
{
	return (NSUInteger)CFAttributedStringGetLength(self);
}
-(BOOL)isEqualToAttributedString:(NSAttributedString *)otherString
{
	return CFEqual(self,otherString);
}

- (NSDictionary*)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
{
    CFIndex length = CFAttributedStringGetLength(self);

    if (index >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException
                                reason: @"index lies beyond the out of the receiver’s characters"
                              userInfo: self];

        [e raise];
    }

	 

	NSDictionary* dic =  NULL;
	if(aRange != nil)	{
	 	CFRange range = CFRangeMake(aRange->location,aRange->length);
		dic = (NSDictionary*)CFAttributedStringGetAttributes(self,index,&range);
		aRange->location = range.location;
		aRange->length = range.length;	
	}
	else
		dic = (NSDictionary*)CFAttributedStringGetAttributes(self,index,NULL);

	return  dic;
}


- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
{
    CFIndex length = CFAttributedStringGetLength(self);

    if (index >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException
                                    reason: @"index lies beyond the out of the receiver’s characters"
                                  userInfo: self];
        [e raise];
    }
    CFRange range = CFRangeMake(0,0);
	id obj = CFAttributedStringGetAttribute (self,index,attributeName, &range);
	if(aRange != nil)
	{
		aRange->location = range.location;
		aRange->length = range.length;
	}	
	return obj;
}

- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit
{
    CFIndex length = CFAttributedStringGetLength(self);

    if (index >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException
                                    reason: @"index lies beyond the out of the receiver’s characters"
                                  userInfo: self];
        [e raise];
    }
    CFRange range = CFRangeMake(0,0);
	id obj = CFAttributedStringGetAttributeAndLongestEffectiveRange (self,index,attributeName,CFRangeMake(rangeLimit.location,rangeLimit.length),&range);
	if(aRange != nil){
	aRange->location = range.location;
	aRange->length = range.length;
	}
	return obj;

}



- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit
{
    CFIndex length = CFAttributedStringGetLength(self);

    if (index >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException
                                    reason: @"index lies beyond the out of the receiver's characters"
                                  userInfo: self];
        [e raise];
    }

	CFRange range = CFRangeMake(0,0);
	NSDictionary* dic = (NSDictionary *)CFAttributedStringGetAttributesAndLongestEffectiveRange (self,index,CFRangeMake(rangeLimit.location,rangeLimit.length),&range);
	if(aRange != nil){	
	aRange->location = range.location;
	aRange->length = range.length;
} 
	return dic;
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)aRange
{
    CFIndex length = CFAttributedStringGetLength(self);
    if (aRange.location < 0 || aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException
                                    reason: @"index lies beyond the out of the receiver's characters"
                                  userInfo: self];
        [e raise];
    }
    
    NSString* str =  CFAttributedStringGetString(self);
    NSString* sub = [str substringWithRange:aRange];

	CFIndex i = aRange.location;
    length = aRange.location + aRange.length; 
	CFDictionaryRef dic = NULL;	

	CFMutableAttributedStringRef mutable = CFAttributedStringCreateMutable(NULL,0);
	CFAttributedStringReplaceString (mutable,CFRangeMake(0,0),sub);
	for(; i < length ; ++i)
	{
		dic = CFAttributedStringGetAttributes(self,i,NULL);
		if(dic != NULL )
			CFAttributedStringSetAttributes ( mutable, CFRangeMake(i-aRange.location,1), CFDictionaryCreateCopy(NULL,dic), true);
	}

	CFAttributedStringRef attributedString = CFAttributedStringCreateCopy(NULL,mutable);
	CFRelease(mutable);
	

	return attributedString;
}


- (NSMutableString *)mutableString
{
    return (NSMutableString*) CFAttributedStringGetMutableString (self);
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString
{
    CFAttributedStringReplaceString (self,CFRangeMake(aRange.location,aRange.length),aString);
}


- (void)deleteCharactersInRange:(NSRange)aRange
{

    CFIndex length = CFAttributedStringGetLength(self);
    
    if (aRange.location < 0 ||aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"aRange lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }
     CFAttributedStringReplaceString (self,CFRangeMake(aRange.location,aRange.length),@"");
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    CFAttributedStringSetAttributes (self,CFRangeMake(aRange.location,aRange.length),attributes,true);
}

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)aRange
{
    
    if(name == nil)
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSInvalidArgumentException
                                    reason: @"name or value is nil "
                                  userInfo: self];
        [e raise];
        
        
    }
    
    CFIndex length = CFAttributedStringGetLength(self);
    
    if (aRange.location < 0 || aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"aRange lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }

    CFAttributedStringSetAttribute (self,CFRangeMake(aRange.location,aRange.length),name,value);
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    if(attributes == nil)
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSInvalidArgumentException
                                    reason: @"attributes is nil "
                                  userInfo: self];
        [e raise];
        
        
    }
    
    CFIndex length = CFAttributedStringGetLength(self);
    
    if (aRange.location < 0 || aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"aRange lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }
    CFAttributedStringSetAttributes (self,CFRangeMake(aRange.location,aRange.length),attributes,false);
}

- (void)removeAttribute:(NSString *)name range:(NSRange)aRange
{
    
    if(name == nil)
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSInvalidArgumentException
                                    reason: @"name or value is nil "
                                  userInfo: self];
        [e raise];
        
        
    }
    
    CFIndex length = CFAttributedStringGetLength(self);
    
    if (aRange.location < 0 || aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"aRange lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }
    CFAttributedStringRemoveAttribute (self,CFRangeMake(aRange.location,aRange.length),name);
}


- (void)appendAttributedString:(NSAttributedString *)attributedString
{
    CFStringRef str1 = CFAttributedStringGetString(self);
    CFStringRef str2 = CFAttributedStringGetString(attributedString);
    CFIndex location = CFStringGetLength(str1);
    CFIndex length =  CFStringGetLength(str2);
    CFRange range = CFRangeMake(location,length);
    CFStringAppend (str1,str2);
    CFAttributedStringReplaceAttributedString (self,range,attributedString);

}

- (void)insertAttributedString:(NSAttributedString *)attributedString atIndex:(NSUInteger)index
{
    
       
    CFIndex length = CFAttributedStringGetLength(self);
    
    if (index < 0 || index >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"index lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }
    CFMutableStringRef strThis =  CFAttributedStringGetString(self);
    CFMutableStringRef str =  CFAttributedStringGetString(attributedString);
    CFIndex lengthThis = CFStringGetLength(strThis);
    length = CFStringGetLength(str);
        
    CFMutableArrayRef arr =  CFArrayCreateMutable (NULL,lengthThis,NULL );
   
    CFIndex i = index + 1;
    
    for(; i < lengthThis; ++i)
    {
        CFArraySetValueAtIndex (arr,i,CFAttributedStringGetAttributes(self,i,NULL));
    }
    
    CFStringInsert (strThis,index,str);
    lengthThis = CFStringGetLength(strThis);
    
    i = index + length+1;
    for(; i < lengthThis; ++i)
    {
        CFDictionaryRef dic = CFArrayGetValueAtIndex (arr,i);
        if(dic != NULL)
        {
             CFAttributedStringSetAttributes (self ,CFRangeMake(i,1),dic,true);
        }
    }
    
    CFIndex j = 0;
    i = index + 1;
    for(; j < length; ++j,++i)
    {
		CFDictionaryRef dic = CFDictionaryCreateCopy(NULL,CFAttributedStringGetAttributes(self,i,NULL));
        CFAttributedStringSetAttributes (self ,CFRangeMake(i,1),dic,true);
        
    }
    CFRelease(arr);
}




- (void)replaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString *)attributedString
{
    
    if(attributedString == nil)
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSInvalidArgumentException
                                    reason: @"attributedString parameter  is nil "
                                  userInfo: self];
        [e raise];
        
        
    }
    
    CFIndex length = CFAttributedStringGetLength(self);
    
    if (aRange.location < 0 || aRange.location + aRange.length >= length )
    {
        NSException *e;
        e = [NSException exceptionWithName:  NSRangeException 
                                    reason: @"aRange lies beyond the end of the receiver’s characters."
                                  userInfo: self];
        [e raise];
    }
    CFAttributedStringReplaceAttributedString (self, CFRangeMake(aRange.location,aRange.length),attributedString);
    
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	//[self release];
    self = CFAttributedStringCreateMutableCopy (NULL,0,attributedString);
}


- (void) dealloc
{
  CFRelease(self);
}

@end



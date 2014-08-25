/*
 * Copyright (c) 2013. All rights reserved.
 *
 */
 
#include "CFAttributedString.h"
#include "CFRuntime.h"
#include "CFBase.h"
#include "CFString.h"
#include "CFDictionary.h"
#include "GSPrivate.h"

#include <string.h>
#include <assert.h>

#include <stdio.h>
#include <stdlib.h>



enum
{
  _kCFAttributedStringIsMutable = (1<<0),
  _kCFAttributedStringIsImmutable = (1<<1)
};

/*
static struct __CFAttr
{

  const CFDictionaryRef    _attr;
  CFIndex	_index;
};
*/

struct __CFAttributedString
{
  CFRuntimeBase           _parent;
  CFStringRef            str;
  CFDictionaryRef	 attributes;// key is an index in string array and value is CFDictionaryRef <strName, Object>
};



struct __CFMutableAttributedString
{
  CFRuntimeBase           _parent;
  CFMutableStringRef            str;
  CFDictionaryRef 	attributes;
  

};

static CFTypeID _kCFAttributedStringTypeID = 0;



 void *CFIndexRetain(CFAllocatorRef allocator, const void *ptr) {
    CFIndex *newPtr = (CFIndex*)CFAllocatorAllocate(allocator, sizeof(CFIndex), 0);
    *newPtr = *((CFIndex*)ptr);    
    return newPtr;
}
 
void CFIndexRelease(CFAllocatorRef allocator, const void *ptr) {
    CFAllocatorDeallocate(allocator, (CFIndex *)ptr);
}
 


Boolean CFIndexEqual(const void *ptr1, const void *ptr2) {
    CFIndex *p1 = (CFIndex *)ptr1;
    CFIndex *p2 = (CFIndex *)ptr2;
    return  (*p1 == *p2);
 
}

CFHashCode CFIndexHash(const void *ptr) {
    return (CFHashCode)*((CFIndex*)ptr);
}


static CFDictionaryKeyCallBacks CFIndexDictionaryKeyCallbacks = {0, CFIndexRetain, CFIndexRelease, NULL, CFIndexEqual, CFIndexHash};




static Boolean
CFAttributedStringEqual (CFTypeRef cf1, CFTypeRef cf2)
{
  if(cf1 == NULL || cf2 == NULL)
	return false;
  CFAttributedStringRef aStr1 = (CFAttributedStringRef)cf1;
  CFAttributedStringRef aStr2 = (CFAttributedStringRef)cf2;
  
  if (!CFEqual(aStr1->str,aStr2->str))
    return false;

if(aStr2->attributes == NULL)
	return false;
  CFIndex count1 = CFDictionaryGetCount(aStr1->attributes);	
  CFIndex count2 = CFDictionaryGetCount(aStr2->attributes);	  
	
  if(count1 != count2) 
	return false;  
 
   
  void** keys1 = malloc(sizeof(void*)*count1);
  void** keys2 = malloc(sizeof(void*)*count2);
  CFDictionaryGetKeysAndValues (aStr1->attributes,keys1,NULL);
  CFDictionaryGetKeysAndValues (aStr2->attributes,keys2,NULL);
  CFIndex i = 0;
  
  for(; i < count1 ; ++i)
  {
	
  	CFTypeRef t1 = CFDictionaryGetValue (aStr1->attributes,keys1[i]);	
	CFTypeRef t2 = CFDictionaryGetValue (aStr2->attributes,keys2[i]);
	if(CFEqual(t1,t2) == false)
	{
		free(keys1);
		free(keys2);
		return false;
	}
  }
free(keys1);
free(keys2);

  return true;
}



static CFHashCode
CFAttributedStringHash(CFTypeRef cf)
{
	CFHashCode hash;
	CFAttributedStringRef aStr = (CFAttributedStringRef)cf;
	hash = CFHash(aStr->str);
	hash+= CFDictionaryGetCount(aStr->attributes);
	return hash;
}


static void 
CFAttributedStringFinalize(CFTypeRef cf)
{
	CFAttributedStringRef aStr = (CFAttributedStringRef)cf;
	CFRelease(aStr->str);	
	CFDictionaryRemoveAllValues (aStr->attributes);
	CFRelease(aStr->attributes);
}





static CFRuntimeClass CFAttriburedStringClass =
{
  0,
  "CFAttributedString",
  NULL,
  (CFTypeRef (*)(CFAllocatorRef, CFTypeRef))CFAttributedStringCreateCopy,
  CFAttributedStringFinalize,
  CFAttributedStringEqual,
  CFAttributedStringHash,
  NULL,
  NULL
};




#define CFATTRIBUTEDSTRING_SIZE sizeof(struct __CFAttributedString) - sizeof(CFRuntimeBase)


static CFIndex
CFAttributedStringLastIndexWithAttributed(CFAttributedStringRef aAstr, CFStringRef aAttrName,CFIndex aLoc)
{
	CFIndex index = aLoc ;
	CFIndex size = CFStringGetLength(aAstr->str);
	CFDictionaryRef attributes = aAstr->attributes;
	while ((++index < size) &&  CFDictionaryContainsKey(attributes,&index));
	return index;
}


void CFAttributedStringInitialize(void)
{
  _kCFAttributedStringTypeID = _CFRuntimeRegisterClass (&CFAttriburedStringClass);
}


static CFAttributedStringRef 
CFAttributedStringInit(CFAllocatorRef allocator, CFStringRef aStr,CFDictionaryRef aAttributes)
{ 		
	struct __CFAttributedString *new; 
  	CFStringRef strCopy;
  	CFDictionaryRef attrCopy;
  	new = (struct __CFAttributedString*) _CFRuntimeCreateInstance (allocator,_kCFAttributedStringTypeID,
  		CFATTRIBUTEDSTRING_SIZE, 0);  	
	if(new)
 	{
		//&CFIndexDictionaryKeyCallbacks
	
	  	if(aStr)
	  	{
	  		strCopy =  CFStringCreateCopy (allocator,aStr);
	  		new->str = strCopy;
	  	}
	  	if(aAttributes)
	  	{
			CFIndex count = CFDictionaryGetCount(aAttributes);
			const void ** attributesKeys = (void**)malloc(sizeof(void*)*count);
			const void ** attributesValues = (void**)malloc(sizeof(void*)*count);
			CFDictionaryGetKeysAndValues(aAttributes,attributesKeys,attributesValues);
			attrCopy = CFDictionaryCreate (allocator,attributesKeys,attributesValues,count,&kCFCopyStringDictionaryKeyCallBacks,NULL);
	  		free(attributesKeys);
			free(attributesValues);		  		
			CFIndex i;
	  		CFIndex *indexPtr;
	  		CFIndex size = CFStringGetLength(aStr);
			const void ** keys = (void**)malloc(sizeof(void*)*size);
			const void ** values = (void**)malloc(sizeof(void*)*size);
	  		for(i = 0 ; i < size; i++)
	  		{
				indexPtr = (CFIndex*)CFAllocatorAllocate(allocator, sizeof(CFIndex), 0);
	  			*indexPtr = i;
				keys[i] = indexPtr;
				values[i] = CFRetain(attrCopy);
	  		}			

			new->attributes =  CFDictionaryCreate (allocator,keys,values,size,&CFIndexDictionaryKeyCallbacks,NULL);
			for(i = 0 ; i < size; i++)
				CFAllocatorDeallocate(allocator, (CFIndex *)keys[i]);			
			free(keys);
			free(values);
	  	 	CFRelease(attrCopy);
	  	} 	 
	}

	return new; 
}


CFAttributedStringRef 
CFAttributedStringCreate(CFAllocatorRef allocator, CFStringRef str, CFDictionaryRef attributes)
{
	return CFAttributedStringInit(allocator,str,attributes);
}

CFAttributedStringRef 
CFAttributedStringCreateCopy (CFAllocatorRef allocator,CFAttributedStringRef aStr)
{
 	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "copy");
	struct __CFAttributedString *new; 
  	new = (struct __CFAttributedString*) _CFRuntimeCreateInstance (allocator,_kCFAttributedStringTypeID,
  		CFATTRIBUTEDSTRING_SIZE, 0);  	
	if(new)
 	{
	  	new->str =  CFStringCreateCopy (allocator,aStr->str);

		new->attributes =  CFDictionaryCreateCopy (allocator,aStr->attributes);
	}
	return new;
}


CFAttributedStringRef 
CFAttributedStringCreateWithSubstring (CFAllocatorRef allocator,CFAttributedStringRef aStr,CFRange aRange)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "initWithString:attributes:");
	
	CFStringRef strCopy =  CFStringCreateWithSubstring(allocator,aStr->str,aRange);
	

	struct __CFAttributedString *new; 
  	CFDictionaryRef attrCopy;
  	new = (struct __CFAttributedString*) _CFRuntimeCreateInstance (allocator,_kCFAttributedStringTypeID,
  		CFATTRIBUTEDSTRING_SIZE, 0);
  	if(new)
  	{	
	
  		new->str = strCopy;
		if(aStr->attributes){
	  		CFIndex i;
	  		CFIndex *indexPtr;
	  		CFIndex length = aRange.location + aRange.length;
		  	
			CFIndex size =0;
			for(i = aRange.location ; i < length; i++)
	  		{
	  			if(CFDictionaryContainsKey(aStr->attributes,&i)){
					size++;
	  			}
	  			
	  		}

			
			const void ** keys = (void**)malloc(sizeof(void*)*size);
			const void ** values = (void**)malloc(sizeof(void*)*size);
			 CFIndex effectedInex =0;  		
			for(i = aRange.location ; i < length; i++)
	  		{
	  			if(CFDictionaryContainsKey(aStr->attributes,&i)){
					attrCopy =  CFDictionaryCreateCopy(allocator,CFDictionaryGetValue(aStr->attributes,&i));
					CFIndex *indexPtr = (CFIndex*)CFAllocatorAllocate(allocator, sizeof(CFIndex), 0);
		  			*indexPtr = i;
		  			keys[effectedInex] = indexPtr;
					values[effectedInex] = attrCopy;
					CFRelease(attrCopy);
					effectedInex++;	
	  			}
	  			
	  		}
			new->attributes =  CFDictionaryCreate (allocator,keys,values,size,&CFIndexDictionaryKeyCallbacks,NULL);
			for(i = 0 ; i < size; i++)
				CFAllocatorDeallocate(allocator, (CFIndex *)keys[i]);
			free(keys);
			free(values);

	  	 	
		  }	 
  	}
  	
	return (CFAttributedStringRef)new; 	
}


static CFTypeRef 
CFAttributedStringGetAttributeDependParameted (CFAttributedStringRef aAStr,CFIndex aLoc,CFStringRef aAttrName,CFRange inRange,CFRange *aEffectiveRange)
{
	if(aEffectiveRange != NULL)
	{
		aEffectiveRange->location = inRange.location;
		aEffectiveRange->length = 0;
	}	
	CFIndex strSize = CFStringGetLength(aAStr->str);
	

	if(aLoc >= strSize)
		return NULL;
		
	CFDictionaryRef attributes = CFDictionaryGetValue( aAStr->attributes,&aLoc);
	if(attributes == NULL )
		return NULL;
	if(!CFDictionaryContainsKey(attributes,aAttrName))
		return NULL;
	CFTypeRef returnedType = (CFTypeRef)CFDictionaryGetValue(attributes,aAttrName);	
	
	CFIndex i ; 
	CFIndex len = aLoc + inRange.length; 
	for(i = inRange.location ; i < len; ++i)
	{
		attributes   =  CFDictionaryGetValue(aAStr->attributes,&i)  ;
		if(attributes == NULL || !CFDictionaryContainsKey(attributes,aAttrName))
			break;	
	}

	aEffectiveRange->length = i - inRange.location;
	return (CFTypeRef)returnedType;
	
}


CFDictionaryRef CFAttributedStringGetAttributes (CFAttributedStringRef aStr,CFIndex loc,CFRange *effectiveRange)
{

	CFDictionaryRef dic = NULL;
	if(CFDictionaryContainsKey(aStr->attributes,&loc))
	{
		dic  = CFDictionaryGetValue(aStr->attributes,&loc);
		if(effectiveRange != NULL)
		{
			effectiveRange->location = loc;
			CFIndex i = 0;
			CFIndex length = CFStringGetLength(aStr->str);	
			for(; i < length; ++i )			
			{
				CFDictionaryRef jthDec =CFDictionaryGetValue(aStr->attributes,&i);
				if(!CFEqual(jthDec,dic))
					break;
			}
		effectiveRange->length =  i;				
		}
		
	}
	return dic;
	
}

CFTypeRef 
CFAttributedStringGetAttribute (CFAttributedStringRef aAStr,CFIndex aLoc,CFStringRef aAttrName,CFRange *aEffectiveRange)
{ 
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aAStr, "attribute:atIndex:effectiveRange:");
	CFIndex len = CFStringGetLength(aAStr->str);
	return CFAttributedStringGetAttributeDependParameted ( aAStr, aLoc, aAttrName,CFRangeMake(aLoc,len - aLoc), aEffectiveRange);
}

CFTypeRef 
CFAttributedStringGetAttributeAndLongestEffectiveRange (CFAttributedStringRef aStr,CFIndex loc,CFStringRef attrName,CFRange  inRange,CFRange *longestEffectiveRange)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "attribute:atIndex:longestEffectiveRange:inRange:");

	return CFAttributedStringGetAttributeDependParameted ( aStr,loc, attrName,inRange, longestEffectiveRange);
}

CFDictionaryRef CFAttributedStringGetAttributesAndLongestEffectiveRange (CFAttributedStringRef aStr,CFIndex loc,CFRange inRange,CFRange *longestEffectiveRange)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "attributesAtIndex:longestEffectiveRange:inRange");

	if(longestEffectiveRange != NULL)
	{
		longestEffectiveRange->location = inRange.location;
		longestEffectiveRange->length = 0;
	}	
	CFIndex strSize = CFStringGetLength(aStr->str);
	

	if(loc >= strSize)
		return NULL;
		
	CFDictionaryRef attributes = CFDictionaryGetValue( aStr->attributes,&loc);
	if(attributes == NULL )
		return NULL;
	if(longestEffectiveRange != NULL)
	{
		CFIndex i ; 
		CFIndex len = loc + inRange.length;
		for(i = loc + 1 ; i < len; ++i)
		{
			CFDictionaryRef temp   =  CFDictionaryGetValue(aStr->attributes,&i)  ;
			if(temp == NULL)
				break;
			else if(!CFEqual(attributes,temp))
				break;
	
		}

		longestEffectiveRange->length = i - loc;
	}
	return attributes;

}


CFIndex CFAttributedStringGetLength(CFAttributedStringRef aStr)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "length");
	if(aStr->str == NULL)
		return -1;
	return CFStringGetLength(aStr->str);
}

CFStringRef CFAttributedStringGetString(CFAttributedStringRef aStr)
{

	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "string");
	if(aStr->str == NULL)
		return NULL;
	return (CFStringRef)CFRetain(aStr->str);
}


CFTypeID 
CFAttributedStringGetTypeID ()
{
	return 	_kCFAttributedStringTypeID;
}



//------------------------------------------------- MUtable AttributedString ----------------------------------//
#define DEFAULT_ARRAY_CAPACITY 16
#define CFMUTABLEATTRIBUTEDSTRING_SIZE sizeof(struct __CFMutableAttributedString) - sizeof(CFRuntimeBase)

CF_INLINE void
CFAttributedStringSetMutable (CFAttributedStringRef aStr)
{
  ((CFRuntimeBase *)aStr)->_flags.info |= _kCFAttributedStringIsMutable;
}

CF_INLINE Boolean
CFAttributedStringIsMutable (CFAttributedStringRef array)
{
  return ((CFRuntimeBase *)array)->_flags.info & _kCFAttributedStringIsMutable ?
    true : false;
}


CFMutableAttributedStringRef 
CFAttributedStringCreateMutable (CFAllocatorRef allocator,CFIndex maxLength)
{
	assert(maxLength >= 0);
	struct __CFMutableAttributedString *new; 
  	new = (struct __CFMutableAttributedString*) _CFRuntimeCreateInstance (allocator,_kCFAttributedStringTypeID,
  		CFMUTABLEATTRIBUTEDSTRING_SIZE, 0);
  	if(new)
  	{
   
	      new->attributes =  CFDictionaryCreateMutable ( allocator,16,&CFIndexDictionaryKeyCallbacks,NULL);
		  new->str = CFStringCreateMutable (allocator,maxLength);

	      CFAttributedStringSetMutable(new); 	 
  	}
  	
	return (CFMutableAttributedStringRef)new; 
}


CFMutableAttributedStringRef 
CFAttributedStringCreateMutableCopy (CFAllocatorRef allocator,CFIndex maxLength,CFAttributedStringRef aStr)
{
	
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFMutableAttributedStringRef, aStr, "copy");
	if(!aStr)
		return NULL;
	CFMutableAttributedStringRef new = CFAttributedStringCreateMutable(allocator,maxLength);
	if(new){	
		new->str =  CFStringCreateCopy (allocator,aStr->str);	
		new->attributes =  CFDictionaryCreateMutableCopy (allocator,16,aStr->attributes);
	}
	return (CFMutableAttributedStringRef)new; 
}

CFMutableStringRef
CFAttributedStringGetMutableString (CFMutableAttributedStringRef aStr)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "mutableString");
	if(aStr->str == NULL)
		return NULL;
	return aStr->str; 
}

void CFAttributedStringReplaceAttributedString (
   CFMutableAttributedStringRef aStr,
   CFRange range,
   CFAttributedStringRef replacement)
{

	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "replaceCharactersInRange:withAttributedString:");	
	CFIndex stringSize = CFStringGetLength(aStr->str);
	
		
	CFIndex size = range.location + range.length;
	assert(range.location < stringSize &&  size <= stringSize);
	
	CFIndex i = range.location;	
	
	CFStringReplace (aStr->str, range,replacement->str);

	CFIndex to = CFStringGetLength(replacement->str)+i;	


	CFDictionaryRef attributes = NULL;
	for(; i < to ; ++i)
	{
		CFIndex idx = (i-range.location);		
		if(CFDictionaryContainsKey(replacement->attributes,&idx))
		{
			attributes = CFDictionaryGetValue(replacement->attributes,&idx);
			CFAttributedStringSetAttributes ( aStr, CFRangeMake(i,1), CFDictionaryCreateCopy(NULL,attributes), true);
		}
	}
}


void 
CFAttributedStringReplaceString (CFMutableAttributedStringRef aStr,
   CFRange range,
   CFStringRef replacement)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "replaceCharactersInRange:withString:");
	
	 CFStringReplace (aStr->str, range,replacement);
}



void 
CFAttributedStringRemoveAttribute ( CFMutableAttributedStringRef aStr, CFRange range,CFStringRef attrName)
{
	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "removeAttribute:range:");
	CFIndex strSize = CFStringGetLength(aStr->str);
	CFIndex index = range.location;
	CFIndex to = index + range.length;
	CFDictionaryRef  dic;
	for(; index < to ; ++index)
	{
		dic = aStr->attributes;
		if(CFDictionaryContainsKey(dic,&index))
			CFDictionaryRemoveValue ((CFMutableDictionaryRef)CFDictionaryGetValue(dic,&index) ,attrName);
	}
}

void 
CFAttributedStringSetAttribute (CFMutableAttributedStringRef aStr,CFRange range,CFStringRef attrName,CFTypeRef value)
{

	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "addAttribute:value:range:");
	CFIndex strSize = CFStringGetLength(aStr->str);
	CFIndex index = range.location;
	CFIndex to = index + range.length;
	CFDictionaryRef dic =  aStr->attributes;
	CFDictionaryRef attr ;
	for(; index < to ; ++index)
	{
	
		if(CFDictionaryContainsKey(dic,&index))
		{
			attr = CFDictionaryGetValue(dic,&index);
			CFDictionarySetValue (attr,CFRetain(attrName),CFRetain(value));
		}
	}
}


void 
CFAttributedStringSetAttributes ( CFMutableAttributedStringRef aStr,
	CFRange range,CFDictionaryRef replacement
	,Boolean clearOtherAttributes)
{

	CF_OBJC_FUNCDISPATCH0(_kCFAttributedStringTypeID, CFAttributedStringRef, aStr, "setAttributes:range:");	
	
	CFIndex strSize = CFStringGetLength(aStr->str);
	CFIndex index = range.location;
	CFIndex to = index + range.length;

	CFDictionaryRef attributes =  aStr->attributes;
	CFDictionaryRef attr ;
	
	CFIndex count = CFDictionaryGetCount (replacement);
	void** keys = malloc(sizeof(void*)*count);
	void** values = malloc(sizeof(void*)*count);
	CFDictionaryGetKeysAndValues (replacement,keys,values);
	for(; index < to ; ++index)
	{
		if(CFDictionaryContainsKey(attributes,&index)){
			attr = CFDictionaryGetValue(attributes,&index);
		}
		else{
			attr =  CFDictionaryCreateMutable (NULL,16,&kCFCopyStringDictionaryKeyCallBacks ,NULL);	
			CFDictionarySetValue(attributes,&index,attr);
		}
		if(clearOtherAttributes)
			CFDictionaryRemoveAllValues (attr);
		
		CFIndex i = 0;
		for(; i < count ; ++i)// this for loop for retain every values
		{
			//__CFAssertIsString(keys[i]);
			if(keys[i]!= NULL&&values[i] != NULL)  
				CFDictionarySetValue (attr,keys[i],CFRetain(values[i]));
			
		}
	}
	free(keys);
	free(values);
	
}



/* CFBase.c
   
   Copyright (C) 2010-2011 Free Software Foundation, Inc.
   
   Written by: Stefan Bidigaray
   Date: January, 2010
   
   This file is part of GNUstep CoreBase Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#include "CFBase.h"
#include "GSPrivate.h"
#include "CFRuntime.h"

#include <stdlib.h>
#include <string.h>

#include <stdio.h>
//#include <proc/readproc.h>
#include <unistd.h>

const double kCFCoreFoundationVersionNumber = 550.13;



struct __CFAllocator
{
  CFRuntimeBase _parent;
  CFAllocatorContext _context;
};

// this will hold the default zone if set with CFAllocatorSetDefault ()
static CFTypeID _kCFAllocatorTypeID = 0;
static CFAllocatorRef _kCFDefaultAllocator = NULL;

static CFRuntimeClass CFAllocatorClass =
{
  0,
  "CFAllocator",
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
};

void CFAllocatorInitialize (void)
{
  _kCFAllocatorTypeID = _CFRuntimeRegisterClass (&CFAllocatorClass);
  _kCFDefaultAllocator = kCFAllocatorSystemDefault;
  
  /* These are already semi-initialized by INIT_CFRUNTIME_BASE() */
  GSRuntimeConstantInit (kCFAllocatorSystemDefault, _kCFAllocatorTypeID);
  GSRuntimeConstantInit (kCFAllocatorMalloc, _kCFAllocatorTypeID);
  GSRuntimeConstantInit (kCFAllocatorMallocZone, _kCFAllocatorTypeID);
  GSRuntimeConstantInit (kCFAllocatorNull, _kCFAllocatorTypeID);
}

static void *
malloc_alloc (CFIndex allocSize, CFOptionFlags hint, void *info)
{
  return malloc (allocSize);
}

static void *
malloc_realloc (void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
  return realloc (ptr, newsize);
}

static void
malloc_dealloc (void *ptr, void *info)
{
  free (ptr);
}

static void *
null_alloc (CFIndex allocSize, CFOptionFlags hint, void *info)
{
  return NULL;
}

static void *
null_realloc (void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
  return NULL;
}

static void
null_dealloc (void *ptr, void *info)
{
  
}

static struct __CFAllocator _kCFAllocatorSystemDefault =
{
  INIT_CFRUNTIME_BASE(),
  { 0, NULL, NULL, NULL, NULL, malloc_alloc, malloc_realloc, malloc_dealloc, NULL }
};

static struct __CFAllocator _kCFAllocatorNull =
{
  INIT_CFRUNTIME_BASE(),
  { 0, NULL, NULL, NULL, NULL, null_alloc, null_realloc, null_dealloc, NULL }
};

CFAllocatorRef kCFAllocatorDefault = NULL;
/* Just use the default system allocator everywhere! */
CFAllocatorRef kCFAllocatorSystemDefault = &_kCFAllocatorSystemDefault;
CFAllocatorRef kCFAllocatorMalloc = &_kCFAllocatorSystemDefault;
CFAllocatorRef kCFAllocatorMallocZone = &_kCFAllocatorSystemDefault;
CFAllocatorRef kCFAllocatorNull = &_kCFAllocatorNull;
CFAllocatorRef kCFAllocatorUseContext = (CFAllocatorRef)0x01;



CFAllocatorRef
CFAllocatorCreate(CFAllocatorRef allocator, CFAllocatorContext *context)
{
  struct __CFAllocator *new;
  
  if (allocator == kCFAllocatorUseContext)
    {
      /* Chicken and egg problem... */
      return NULL; // FIXME
    }
  else
    {
      new = (struct __CFAllocator*)_CFRuntimeCreateInstance (allocator,
        _kCFAllocatorTypeID,
        sizeof(struct __CFAllocator) - sizeof(CFRuntimeBase),
        0);
      memcpy (&(new->_context), context, sizeof(CFAllocatorContext));
    }
  
  return (CFAllocatorRef)new;
}

void *
CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint)
{
  if (NULL == allocator)
    allocator = _kCFDefaultAllocator;
  
  return allocator->_context.allocate(size, hint, allocator->_context.info);
}

void
CFAllocatorDeallocate(CFAllocatorRef allocator, void *ptr)
{
  if (NULL == allocator)
    allocator = _kCFDefaultAllocator;
  
  allocator->_context.deallocate(ptr, allocator->_context.info);
}

CFIndex
CFAllocatorGetPreferredSizeForSize(CFAllocatorRef allocator, CFIndex size,
  CFOptionFlags hint)
{
  if (allocator == NULL)
    allocator = _kCFDefaultAllocator;
  
  if (allocator->_context.preferredSize)
    return allocator->_context.preferredSize (size, hint,
      allocator->_context.info);
  
  return size;
}

void *
CFAllocatorReallocate(CFAllocatorRef allocator, void *ptr, CFIndex newsize, CFOptionFlags hint)
{
  if (NULL == allocator)
    allocator = _kCFDefaultAllocator;
  
  return allocator->_context.reallocate(ptr, newsize, hint,
    allocator->_context.info);
}

CFAllocatorRef
CFAllocatorGetDefault(void)
{
  return _kCFDefaultAllocator;
}

void
CFAllocatorSetDefault(CFAllocatorRef allocator)
{
  CFAllocatorRef current = _kCFDefaultAllocator;
  
  if (allocator == NULL)
    return;
  
  CFRetain (allocator);
  _kCFDefaultAllocator = allocator;
  CFRelease (current);
}

void
CFAllocatorGetContext(CFAllocatorRef allocator, CFAllocatorContext *context)
{
  context = (CFAllocatorContext*)&(allocator->_context);
}

CFTypeID
CFAllocatorGetTypeID(void)
{
  return _kCFAllocatorTypeID;
}



//
// CFNull
//
static CFTypeID _kCFNullTypeID;

static const CFRuntimeClass CFNullClass =
{
  0,
  "CFNUll",
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
};

struct __CFNull
{
  CFRuntimeBase _parent;
};

static struct __CFNull _kCFNull =
{
  INIT_CFRUNTIME_BASE()
};

CFNullRef kCFNull = &_kCFNull;

void CFNullInitialize (void)
{
  _kCFNullTypeID = _CFRuntimeRegisterClass (&CFNullClass);
  _CFRuntimeSetInstanceTypeID (&_kCFNull, _kCFNullTypeID);
  GSRuntimeConstantInit (kCFNull, _kCFNullTypeID);
}

CFTypeID
CFNullGetTypeID (void)
{
  return _kCFNullTypeID;
}

/*
natural_t CFGetFreeMemory()
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }
     Stats in bytes 
    natural_t mem_free = vm_stat.free_count * pagesize;
    return mem_free;
}*/
/*
unsigned long CFGetMemoryUsage()
{
    struct proc_t usage;
    look_up_our_self(&usage);
    //printf("usage.vsize: %lu\n", usage.vsize);
    //printf("usage.size: %lu\n", usage.size);
    unsigned long pageSize = sysconf(_SC_PAGESIZE);
    //printf("page size: %lu\n", pageSize);
    return usage.vsize;
}*/

long CFGetFreeMemory()
{
    FILE *fp = fopen("/proc/meminfo", "r");
    if (fp!=NULL) {
        size_t bufsize = 1024 * sizeof(char);
        char *buf = (char *)malloc(bufsize);
        long value = -1L;
        while (getline(&buf, &bufsize, fp) >= 0) {
            if (strncmp(buf, "MemFree", 7) != 0) {
                continue;
            }
            sscanf(buf, "MemFree: %ld", &value);
            break;
        }
        fclose(fp);
        free((void *)buf);
        return value;
    }
    return 0;
}


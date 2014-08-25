/** Implementation of NSNotificationCenter for GNUstep
   Copyright (C) 1999 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Created: June 1999

   Many thanks for the earlier version, (from which this is loosely
   derived) by  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Created: March 1996

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   <title>NSNotificationCenter class reference</title>
   $Date: 2012-01-30 03:31:40 -0800 (Mon, 30 Jan 2012) $ $Revision: 34665 $
*/

#import "common.h"
#define	EXPOSE_NSNotificationCenter_IVARS	1
#import "Foundation/NSNotification.h"
#import "Foundation/NSException.h"
#import "Foundation/NSLock.h"
#import "Foundation/NSThread.h"
#import "GNUstepBase/GSLock.h"
#import "GNUstepBase/NSObject+GNUstepBase.h"

static NSZone	*_zone = 0;

/**
 * Concrete class implementing NSNotification.
 */
@interface	GSNotification : NSNotification
{
@public
  NSString	*_name;
  id		_object;
  NSDictionary	*_info;
}
@end

@implementation GSNotification

static Class concrete = 0;

+ (void) initialize
{
  if (concrete == 0)
    {
      concrete = [GSNotification class];
    }
}

+ (NSNotification*) notificationWithName: (NSString*)name
				  object: (id)object
			        userInfo: (NSDictionary*)info
{
  GSNotification	*n;

  n = (GSNotification*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  n->_name = [name copyWithZone: [self zone]];
  n->_object = TEST_RETAIN(object);
  n->_info = TEST_RETAIN(info);
  return AUTORELEASE(n);
}

- (id) copyWithZone: (NSZone*)zone
{
  GSNotification	*n;

  if (NSShouldRetainWithZone (self, zone))
    {
      return [self retain];
    }
  n = (GSNotification*)NSAllocateObject(concrete, 0, NSDefaultMallocZone());
  n->_name = [_name copyWithZone: [self zone]];
  n->_object = TEST_RETAIN(_object);
  n->_info = TEST_RETAIN(_info);
  return n;
}

- (void) dealloc
{
  RELEASE(_name);
  TEST_RELEASE(_object);
  TEST_RELEASE(_info);
  [super dealloc];
}

- (NSString*) name
{
  return _name;
}

- (id) object
{
  return _object;
}

- (NSDictionary*) userInfo
{
  return _info;
}

@end


/*
 * Garbage collection considerations -
 * The notification center is not supposed to retain any notification
 * observers or notification objects.  To achieve this when using garbage
 * collection, we must hide all references to observers and objects.
 * Within an Observation structure, this is not a problem, we simply
 * allocate the structure using 'atomic' allocation to tell the gc
 * system to ignore pointers inside it.
 * Elsewhere, we store the pointers with a bit added, to hide them from
 * the garbage collector.
 */

struct	NCTbl;		/* Notification Center Table structure	*/

/*
 * Observation structure - One of these objects is created for
 * each -addObserver... request.  It holds the requested selector,
 * name and object.  Each struct is placed in one LinkedList,
 * as keyed by the NAME/OBJECT parameters.
 * If 'next' is 0 then the observation is unused (ie it has been
 * removed from, or not yet added to  any list).  The end of a
 * list is marked by 'next' being set to 'ENDOBS'.
 *
 * This is normally a structure which handles memory management using a fast
 * reference count mechanism, but when built with clang for GC, a structure
 * can't hold a zeroing weak pointer to an observer so it's implemented as a
 * trivial class instead ... and gets managed by the garbage collector.
 */

#ifdef __OBJC_GC__

@interface	GSObservation : NSObject
{
  @public
  __weak id	observer;	/* Object to receive message.	*/
  SEL		selector;	/* Method selector.		*/
  IMP		method;		/* Method implementation.	*/
  struct Obs	*next;		/* Next item in linked list.	*/
  struct NCTbl	*link;		/* Pointer back to chunk table	*/
}
@end
@implementation	GSObservation
@end
#define	Observation	GSObservation

#else

typedef	struct	Obs {
  id		observer;	/* Object to receive message.	*/
  SEL		selector;	/* Method selector.		*/
  IMP		method;		/* Method implementation.	*/
  struct Obs	*next;		/* Next item in linked list.	*/
  int		retained;	/* Retain count for structure.	*/
  struct NCTbl	*link;		/* Pointer back to chunk table	*/
} Observation;

#endif

#define	ENDOBS	((Observation*)-1)

static inline unsigned doHash(NSString* key)
{
  if (key == nil)
    {
      return 0;
    }
  else if (((uintptr_t)key) & 1)
    {
      return (unsigned)(uintptr_t)key;
    }
  else
    {
      return [key hash];
    }
}

static inline BOOL doEqual(NSString* key1, NSString* key2)
{
  if (key1 == key2)
    {
      return YES;
    }
  else if ((((uintptr_t)key1) & 1) || key1 == nil)
    {
      return NO;
    }
  else
    {
      return [key1 isEqualToString: key2];
    }
}

/*
 * Setup for inline operation on arrays of Observers.
 */
static void listFree(Observation *list);

#ifdef __OBJC_GC__

/* Observations are managed by the GC system because they need to be
 * instances of a class in order to implement weak pointer to observer.
 */
#define	obsRetain(X)
#define	obsFree(X)

#else

/* Observations have retain/release counts managed explicitly by fast
 * function calls.
 */
static void obsRetain(Observation *o);
static void obsFree(Observation *o);

#endif


#define GSI_ARRAY_TYPES	0
#define GSI_ARRAY_TYPE	Observation*
#ifdef __OBJC_GC__
#define GSI_ARRAY_NO_RELEASE	1
#define GSI_ARRAY_NO_RETAIN	1
#else
#define GSI_ARRAY_RELEASE(A, X)   obsFree(X.ext)
#define GSI_ARRAY_RETAIN(A, X)    obsRetain(X.ext)
#endif

#include "GNUstepBase/GSIArray.h"

#define GSI_MAP_RETAIN_KEY(M, X)
#define GSI_MAP_RELEASE_KEY(M, X) ({if ((((uintptr_t)X.obj) & 1) == 0) \
  RELEASE(X.obj);})
#define GSI_MAP_HASH(M, X)        doHash(X.obj)
#define GSI_MAP_EQUAL(M, X,Y)     doEqual(X.obj, Y.obj)
#define GSI_MAP_RETAIN_VAL(M, X)
#define GSI_MAP_RELEASE_VAL(M, X)

#define GSI_MAP_KTYPES GSUNION_OBJ|GSUNION_NSINT
#define GSI_MAP_VTYPES GSUNION_PTR
#define GSI_MAP_VEXTRA Observation*
#define	GSI_MAP_EXTRA	void*

#if	GS_WITH_GC
#include	<gc/gc_typed.h>
static GC_descr	nodeDesc;	// Type descriptor for map node.
#define	GSI_MAP_NODES(M, X) \
(GSIMapNode)GC_calloc_explicitly_typed(X, sizeof(GSIMapNode_t), nodeDesc)
#endif

#include "GNUstepBase/GSIMap.h"

/*
 * An NC table is used to keep track of memory allocated to store
 * Observation structures. When an Observation is removed from the
 * notification center, it's memory is returned to the free list of
 * the chunk table, rather than being released to the general
 * memory allocation system.  This means that, once a large numbner
 * of observers have been registered, memory usage will never shrink
 * even if the observers are removed.  On the other hand, the process
 * of adding and removing observers is speeded up.
 *
 * As another minor aid to performance, we also maintain a cache of
 * the map tables used to keep mappings of notification objects to
 * lists of Observations.  This lets us avoid the overhead of creating
 * and destroying map tables when we are frequently adding and removing
 * notification observations.
 *
 * Performance is however, not the primary reason for using this
 * structure - it provides a neat way to ensure that observers pointed
 * to by the Observation structures are not seen as being in use by
 * the garbage collection mechanism.
 */
#define	CHUNKSIZE	128
#define	CACHESIZE	16
typedef struct NCTbl {
  Observation		*wildcard;	/* Get ALL messages.		*/
  GSIMapTable		nameless;	/* Get messages for any name.	*/
  GSIMapTable		named;		/* Getting named messages only.	*/
  unsigned		lockCount;	/* Count recursive operations.	*/
  NSRecursiveLock	*_lock;		/* Lock out other threads.	*/
  Observation		*freeList;
  Observation		**chunks;
  unsigned		numChunks;
  GSIMapTable		cache[CACHESIZE];
  unsigned short	chunkIndex;
  unsigned short	cacheIndex;
} NCTable;

#define	TABLE		((NCTable*)_table)
#define	WILDCARD	(TABLE->wildcard)
#define	NAMELESS	(TABLE->nameless)
#define	NAMED		(TABLE->named)
#define	LOCKCOUNT	(TABLE->lockCount)

static Observation *
obsNew(NCTable *t, SEL s, IMP m, id o)
{
  Observation	*obs;

#if __OBJC_GC__

  /* With clang GC, observations are garbage collected and we don't
   * use a cache.  However, because the reference to the observer must be
   * weak, the observation has to be an instance of a class ...
   */
  static Class observationClass;

  if (0 == observationClass)
    {
      observationClass = [GSObservation class];
    }
  obs = NSAllocateObject(observationClass, 0, _zone);

#else

  /* Generally, observations are cached and we create a 'new' observation
   * by retrieving from the cache or by allocating a block of observations
   * in one go.  This works nicely to both hide observations from the
   * garbage collector (when using gcc for GC) and to provide high
   * performance for situations where apps add/remove lots of observers
   * very frequently (poor design, but something which happens in the
   * real world unfortunately).
   */
  if (t->freeList == 0)
    {
      Observation	*block;

      if (t->chunkIndex == CHUNKSIZE)
	{
	  unsigned	size;

	  t->numChunks++;

	  size = t->numChunks * sizeof(Observation*);
	  t->chunks = (Observation**)NSReallocateCollectable(
	    t->chunks, size, NSScannedOption);

	  size = CHUNKSIZE * sizeof(Observation);
	  t->chunks[t->numChunks - 1]
	    = (Observation*)NSAllocateCollectable(size, 0);
	  t->chunkIndex = 0;
	}
      block = t->chunks[t->numChunks - 1];
      t->freeList = &block[t->chunkIndex];
      t->chunkIndex++;
      t->freeList->link = 0;
    }
  obs = t->freeList;
  t->freeList = (Observation*)obs->link;
  obs->link = (void*)t;
  obs->retained = 0;
  obs->next = 0;
#endif

  obs->selector = s;
  obs->method = m;
#if	GS_WITH_GC
  GSAssignZeroingWeakPointer((void**)&obs->observer, (void*)o);
#else
  obs->observer = o;
#endif

  return obs;
}

static GSIMapTable	mapNew(NCTable *t)
{
  if (t->cacheIndex > 0)
    {
      return t->cache[--t->cacheIndex];
    }
  else
    {
      GSIMapTable	m;

      m = NSAllocateCollectable(sizeof(GSIMapTable_t), NSScannedOption);
      GSIMapInitWithZoneAndCapacity(m, _zone, 2);
      return m;
    }
}

static void	mapFree(NCTable *t, GSIMapTable m)
{
  if (t->cacheIndex < CACHESIZE)
    {
      t->cache[t->cacheIndex++] = m;
    }
  else
    {
      GSIMapEmptyMap(m);
      NSZoneFree(NSDefaultMallocZone(), (void*)m);
    }
}

static void endNCTable(NCTable *t)
{
  unsigned		i;
  GSIMapEnumerator_t	e0;
  GSIMapNode		n0;
  Observation		*l;

  TEST_RELEASE(t->_lock);

  /*
   * Free observations without notification names or numbers.
   */
  listFree(t->wildcard);

  /*
   * Free lists of observations without notification names.
   */
  e0 = GSIMapEnumeratorForMap(t->nameless);
  n0 = GSIMapEnumeratorNextNode(&e0);
  while (n0 != 0)
    {
      l = (Observation*)n0->value.ptr;
      n0 = GSIMapEnumeratorNextNode(&e0);
      listFree(l);
    }
  GSIMapEmptyMap(t->nameless);
  NSZoneFree(NSDefaultMallocZone(), (void*)t->nameless);

  /*
   * Free lists of observations keyed by name and observer.
   */
  e0 = GSIMapEnumeratorForMap(t->named);
  n0 = GSIMapEnumeratorNextNode(&e0);
  while (n0 != 0)
    {
      GSIMapTable		m = (GSIMapTable)n0->value.ptr;
      GSIMapEnumerator_t	e1 = GSIMapEnumeratorForMap(m);
      GSIMapNode		n1 = GSIMapEnumeratorNextNode(&e1);

      n0 = GSIMapEnumeratorNextNode(&e0);

      while (n1 != 0)
	{
	  l = (Observation*)n1->value.ptr;
	  n1 = GSIMapEnumeratorNextNode(&e1);
	  listFree(l);
	}
      GSIMapEmptyMap(m);
      NSZoneFree(NSDefaultMallocZone(), (void*)m);
    }
  GSIMapEmptyMap(t->named);
  NSZoneFree(NSDefaultMallocZone(), (void*)t->named);

  for (i = 0; i < t->numChunks; i++)
    {
      NSZoneFree(NSDefaultMallocZone(), t->chunks[i]);
    }
  for (i = 0; i < t->cacheIndex; i++)
    {
      GSIMapEmptyMap(t->cache[i]);
      NSZoneFree(NSDefaultMallocZone(), (void*)t->cache[i]);
    }
  NSZoneFree(NSDefaultMallocZone(), t->chunks);
  NSZoneFree(NSDefaultMallocZone(), t);
}

static NCTable *newNCTable(void)
{
  NCTable	*t;

  t = (NCTable*)NSAllocateCollectable(sizeof(NCTable), NSScannedOption);
  t->chunkIndex = CHUNKSIZE;
  t->wildcard = ENDOBS;

  t->nameless = NSAllocateCollectable(sizeof(GSIMapTable_t), NSScannedOption);
  t->named = NSAllocateCollectable(sizeof(GSIMapTable_t), NSScannedOption);
  GSIMapInitWithZoneAndCapacity(t->nameless, _zone, 16);
  GSIMapInitWithZoneAndCapacity(t->named, _zone, 128);

  t->_lock = [NSRecursiveLock new];
  return t;
}

static inline void lockNCTable(NCTable* t)
{
  [t->_lock lock];
  t->lockCount++;
}

static inline void unlockNCTable(NCTable* t)
{
  t->lockCount--;
  [t->_lock unlock];
}

#ifndef __OBJC_GC__
static void obsFree(Observation *o)
{
  NSCAssert(o->retained >= 0, NSInternalInconsistencyException);
  if (o->retained-- == 0)
    {
      NCTable	*t = o->link;

#if	GS_WITH_GC
      GSAssignZeroingWeakPointer((void**)&o->observer, 0);
#endif
      o->link = (NCTable*)t->freeList;
      t->freeList = o;
    }
}

static void obsRetain(Observation *o)
{
  o->retained++;
}
#endif

static void listFree(Observation *list)
{
  while (list != ENDOBS)
    {
      Observation	*o = list;

      list = o->next;
      o->next = 0;
      obsFree(o);
    }
}

/*
 *	NB. We need to explicitly set the 'next' field of any observation
 *	we remove to be zero so that, if it currently exists in an array
 *	of observations being posted, the posting code can notice that it
 *	has been removed from its linked list.
 *
 *	Also, 
 */
static Observation *listPurge(Observation *list, id observer)
{
  Observation	*tmp;

  while (list != ENDOBS && list->observer == observer)
    {
      tmp = list->next;
      list->next = 0;
      obsFree(list);
      list = tmp;
    }
  if (list != ENDOBS)
    {
      tmp = list;
      while (tmp->next != ENDOBS)
	{
	  if (tmp->next->observer == observer)
	    {
	      Observation	*next = tmp->next;

	      tmp->next = next->next;
	      next->next = 0;
	      obsFree(next);
	    }
	  else
	    {
	      tmp = tmp->next;
	    }
	}
    }
  return list;
}

/*
 * Utility function to remove all the observations from a particular
 * map table node that match the specified observer.  If the observer
 * is nil, then all observations are removed.
 * If the list of observations in the map node is emptied, the node is
 * removed from the map.
 */
static inline void
purgeMapNode(GSIMapTable map, GSIMapNode node, id observer)
{
  Observation	*list = node->value.ext;

  if (observer == 0)
    {
      listFree(list);
      GSIMapRemoveKey(map, node->key);
    }
  else
    {
      Observation	*start = list;

      list = listPurge(list, observer);
      if (list == ENDOBS)
	{
	  /*
	   * The list is empty so remove from map.
	   */
	  GSIMapRemoveKey(map, node->key);
	}
      else if (list != start)
	{
	  /*
	   * The list is not empty, but we have changed its
	   * start, so we must place the new head in the map.
	   */
	  node->value.ext = list;
	}
    }
}

/* purgeCollected() returns a list of observations with any observations for
 * a collected observer removed.
 * purgeCollectedFromMapNode() does the same thing but also handles cleanup
 * of the map node containing the list if necessary.
 */
#if	GS_WITH_GC
#define	purgeCollected(X)	listPurge(X, nil)
static Observation*
purgeCollectedFromMapNode(GSIMapTable map, GSIMapNode node)
{
  Observation	*o;

  o = node->value.ext = purgeCollected((Observation*)(node->value.ext));
  if (o == ENDOBS)
    {
      GSIMapRemoveKey(map, node->key);
    }
  return o;
}
#else
#define	purgeCollected(X)	(X)
#define purgeCollectedFromMapNode(X, Y) ((Observation*)Y->value.ext)
#endif

/*
 * In order to hide pointers from garbage collection, we OR in an
 * extra bit.  This should be ok for the objects we deal with
 * which are all aligned on 4 or 8 byte boundaries on all the machines
 * I know of.
 *
 * We also use this trick to differentiate between map table keys that
 * should be treated as objects (notification names) and those that
 * should be treated as pointers (notification objects)
 */
#define	CHEATGC(X)	(id)(((uintptr_t)X) | 1)



/**
 * <p>GNUstep provides a framework for sending messages between objects within
 * a process called <em>notifications</em>.  Objects register with an
 * <code>NSNotificationCenter</code> to be informed whenever other objects
 * post [NSNotification]s to it matching certain criteria. The notification
 * center processes notifications synchronously -- that is, control is only
 * returned to the notification poster once every recipient of the
 * notification has received it and processed it.  Asynchronous processing is
 * possible using an [NSNotificationQueue].</p>
 *
 * <p>Obtain an instance using the +defaultCenter method.</p>
 *
 * <p>In a multithreaded process, notifications are always sent on the thread
 * that they are posted from.</p>
 *
 * <p>Use the [NSDistributedNotificationCenter] for interprocess
 * communications on the same machine.</p>
 */
@implementation NSNotificationCenter

/* The default instance, most often the only one created.
   It is accessed by the class methods at the end of this file.
   There is no need to mutex locking of this variable. */

static NSNotificationCenter *default_center = nil;

+ (void) atExit
{
  id	tmp = default_center;

  default_center = nil;
  [tmp release];
}

+ (void) initialize
{
  if (self == [NSNotificationCenter class])
    {
#if	GS_WITH_GC
      /* We create a typed memory descriptor for map nodes.
       */
      GC_word	w[GC_BITMAP_SIZE(GSIMapNode_t)] = {0};
      GC_set_bit(w, GC_WORD_OFFSET(GSIMapNode_t, key));
      GC_set_bit(w, GC_WORD_OFFSET(GSIMapNode_t, value));
      nodeDesc = GC_make_descriptor(w, GC_WORD_LEN(GSIMapNode_t));
#else
      _zone = NSDefaultMallocZone();
#endif
      if (concrete == 0)
	{
	  concrete = [GSNotification class];
	}
      /*
       * Do alloc and init separately so the default center can refer to
       * the 'default_center' variable during initialisation.
       */
      default_center = [self alloc];
      [default_center init];
      [self registerAtExit];
    }
}

/**
 * Returns the default notification center being used for this task (process).
 * This is used for all notifications posted by the Base library unless
 * otherwise noted.
 */
+ (NSNotificationCenter*) defaultCenter
{
  return default_center;
}


/* Initializing. */

- (id) init
{
  if ((self = [super init]) != nil)
    {
      _table = newNCTable();
    }
  return self;
}

- (void) dealloc
{
  [self finalize];

  [super dealloc];
}

- (void) finalize
{
  if (self == default_center)
    {
      [NSException raise: NSInternalInconsistencyException
		  format: @"Attempt to destroy the default center"];
    }
  /*
   * Release all memory used to store Observations etc.
   */
  endNCTable(TABLE);
}


/* Adding new observers. */

/**
 * <p>Registers observer to receive notifications with the name
 * notificationName and/or containing object (one or both of these two must be
 * non-nil; nil acts like a wildcard).  When a notification of name name
 * containing object is posted, observer receives a selector message with this
 * notification as the argument.  The notification center waits for the
 * observer to finish processing the message, then informs the next registree
 * matching the notification, and after all of this is done, control returns
 * to the poster of the notification.  Therefore the processing in the
 * selector implementation should be short.</p>
 *
 * <p>The notification center does not retain observer or object. Therefore,
 * you should always send removeObserver: or removeObserver:name:object: to
 * the notification center before releasing these objects.<br />
 * As a convenience, when built with garbage collection, you do not need to
 * remove any garbage collected observer as the system will do it implicitly.
 * </p>
 *
 * <p>NB. For MacOS-X compatibility, adding an observer multiple times will
 * register it to receive multiple copies of any matching notification, however
 * removing an observer will remove <em>all</em> of the multiple registrations.
 * </p>
 */
- (void) addObserver: (id)observer
	    selector: (SEL)selector
                name: (NSString*)name
	      object: (id)object
{
  IMP		method;
  Observation	*list;
  Observation	*o;
  GSIMapTable	m;
  GSIMapNode	n;

  if (observer == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"Nil observer passed to addObserver ..."];

  if (selector == 0)
    [NSException raise: NSInvalidArgumentException
		format: @"Null selector passed to addObserver ..."];

#if	defined(DEBUG)
  if ([observer respondsToSelector: selector] == NO)
    NSLog(@"Observer '%@' does not respond to selector '%@'", observer,
      NSStringFromSelector(selector));
#endif

  method = [observer methodForSelector: selector];
  if (method == 0)
    [NSException raise: NSInvalidArgumentException
		format: @"Observer can not handle specified selector"];

  lockNCTable(TABLE);

  o = obsNew(TABLE, selector, method, observer);

  if (object != nil)
    {
      object = CHEATGC(object);
    }

  /*
   * Record the Observation in one of the linked lists.
   *
   * NB. It is possible to register an observer for a notification more than
   * once - in which case, the observer will receive multiple messages when
   * the notification is posted... odd, but the MacOS-X docs specify this.
   */

  if (name)
    {
      /*
       * Locate the map table for this name - create it if not present.
       */
      n = GSIMapNodeForKey(NAMED, (GSIMapKey)(id)name);
      if (n == 0)
	{
	  m = mapNew(TABLE);
	  /*
	   * As this is the first observation for the given name, we take a
	   * copy of the name so it cannot be mutated while in the map.
	   */
	  name = [name copyWithZone: NSDefaultMallocZone()];
	  GSIMapAddPair(NAMED, (GSIMapKey)(id)name, (GSIMapVal)(void*)m);
	  GS_CONSUMED(name)
	}
      else
	{
	  m = (GSIMapTable)n->value.ptr;
	}

      /*
       * Add the observation to the list for the correct object.
       */
      n = GSIMapNodeForSimpleKey(m, (GSIMapKey)object);
      if (n == 0)
	{
	  o->next = ENDOBS;
	  GSIMapAddPair(m, (GSIMapKey)object, (GSIMapVal)o);
	}
      else
	{
	  list = (Observation*)n->value.ptr;
	  o->next = list->next;
	  list->next = o;
	}
    }
  else if (object)
    {
      n = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)object);
      if (n == 0)
	{
	  o->next = ENDOBS;
	  GSIMapAddPair(NAMELESS, (GSIMapKey)object, (GSIMapVal)o);
	}
      else
	{
	  list = (Observation*)n->value.ptr;
	  o->next = list->next;
	  list->next = o;
	}
    }
  else
    {
      o->next = WILDCARD;
      WILDCARD = o;
    }

  unlockNCTable(TABLE);
}

/**
 * Deregisters observer for notifications matching name and/or object.  If
 * either or both is nil, they act like wildcards.  The observer may still
 * remain registered for other notifications; use -removeObserver: to remove
 * it from all.  If observer is nil, the effect is to remove all registrees
 * for the specified notifications, unless both observer and name are nil, in
 * which case nothing is done.
 */
- (void) removeObserver: (id)observer
		   name: (NSString*)name
                 object: (id)object
{
  if (name == nil && object == nil && observer == nil)
      return;

  /*
   *	NB. The removal algorithm depends on an implementation characteristic
   *	of our map tables - while enumerating a table, it is safe to remove
   *	the entry returned by the enumerator.
   */

  lockNCTable(TABLE);

  if (object != nil)
    {
      object = CHEATGC(object);
    }

  if (name == nil && object == nil)
    {
      WILDCARD = listPurge(WILDCARD, observer);
    }

  if (name == nil)
    {
      GSIMapEnumerator_t	e0;
      GSIMapNode		n0;

      /*
       * First try removing all named items set for this object.
       */
      e0 = GSIMapEnumeratorForMap(NAMED);
      n0 = GSIMapEnumeratorNextNode(&e0);
      while (n0 != 0)
	{
	  GSIMapTable		m = (GSIMapTable)n0->value.ptr;
	  NSString		*thisName = (NSString*)n0->key.obj;

	  n0 = GSIMapEnumeratorNextNode(&e0);
	  if (object == nil)
	    {
	      GSIMapEnumerator_t	e1 = GSIMapEnumeratorForMap(m);
	      GSIMapNode		n1 = GSIMapEnumeratorNextNode(&e1);

	      /*
	       * Nil object and nil name, so we step through all the maps
	       * keyed under the current name and remove all the objects
	       * that match the observer.
	       */
	      while (n1 != 0)
		{
		  GSIMapNode	next = GSIMapEnumeratorNextNode(&e1);

		  purgeMapNode(m, n1, observer);
		  n1 = next;
		}
	    }
	  else
	    {
	      GSIMapNode	n1;

	      /*
	       * Nil name, but non-nil object - we locate the map for the
	       * specified object, and remove all the items that match
	       * the observer.
	       */
	      n1 = GSIMapNodeForSimpleKey(m, (GSIMapKey)object);
	      if (n1 != 0)
		{
		  purgeMapNode(m, n1, observer);
		}
	    }
	  /*
	   * If we removed all the observations keyed under this name, we
	   * must remove the map table too.
	   */
	  if (m->nodeCount == 0)
	    {
	      mapFree(TABLE, m);
	      GSIMapRemoveKey(NAMED, (GSIMapKey)(id)thisName);
	    }
	}

      /*
       * Now remove unnamed items
       */
      if (object == nil)
	{
	  e0 = GSIMapEnumeratorForMap(NAMELESS);
	  n0 = GSIMapEnumeratorNextNode(&e0);
	  while (n0 != 0)
	    {
	      GSIMapNode	next = GSIMapEnumeratorNextNode(&e0);

	      purgeMapNode(NAMELESS, n0, observer);
	      n0 = next;
	    }
	}
      else
	{
	  n0 = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)object);
	  if (n0 != 0)
	    {
	      purgeMapNode(NAMELESS, n0, observer);
	    }
	}
    }
  else
    {
      GSIMapTable		m;
      GSIMapEnumerator_t	e0;
      GSIMapNode		n0;

      /*
       * Locate the map table for this name.
       */
      n0 = GSIMapNodeForKey(NAMED, (GSIMapKey)((id)name));
      if (n0 == 0)
	{
	  unlockNCTable(TABLE);
	  return;		/* Nothing to do.	*/
	}
      m = (GSIMapTable)n0->value.ptr;

      if (object == nil)
	{
	  e0 = GSIMapEnumeratorForMap(m);
	  n0 = GSIMapEnumeratorNextNode(&e0);

	  while (n0 != 0)
	    {
	      GSIMapNode	next = GSIMapEnumeratorNextNode(&e0);

	      purgeMapNode(m, n0, observer);
	      n0 = next;
	    }
	}
      else
	{
	  n0 = GSIMapNodeForSimpleKey(m, (GSIMapKey)object);
	  if (n0 != 0)
	    {
	      purgeMapNode(m, n0, observer);
	    }
	}
      if (m->nodeCount == 0)
	{
	  mapFree(TABLE, m);
	  GSIMapRemoveKey(NAMED, (GSIMapKey)((id)name));
	}
    }
  unlockNCTable(TABLE);
}

/**
 * Deregisters observer from all notifications.  This should be called before
 * the observer is deallocated.
*/
- (void) removeObserver: (id)observer
{
  if (observer == nil)
    return;

  [self removeObserver: observer name: nil object: nil];
}


/**
 * Private method to perform the actual posting of a notification.
 * Release the notification before returning, or before we raise
 * any exception ... to avoid leaks.
 */
- (void) _postAndRelease: (NSNotification*)notification
{
  Observation	*o;
  unsigned	count;
  NSString	*name = [notification name];
  id		object;
  GSIMapNode	n;
  GSIMapTable	m;
  GSIArrayItem	i[64];
  GSIArray_t	b;
  GSIArray	a = &b;
#if	GS_WITH_GC
  NSGarbageCollector	*collector = [NSGarbageCollector defaultCollector];
#endif

  if (name == nil)
    {
      RELEASE(notification);
      [NSException raise: NSInvalidArgumentException
		  format: @"Tried to post a notification with no name."];
    }
  object = [notification object];
  if (object != nil)
    {
      object = CHEATGC(object);
    }

  /*
   * Lock the table of observations while we traverse it.
   *
   * The table of observations contains weak pointers which are zeroed when
   * the observers get garbage collected.  So to avoid consistency problems
   * we disable gc while we copy all the observations we are interested in.
   * We use scanned memory in the array in the case where there are more
   * than the 64 observers we allowed room for on the stack.
   */
#if	GS_WITH_GC
  GSIArrayInitWithZoneAndStaticCapacity(a, (NSZone*)1, 64, i);
  [collector disable];
#else
  GSIArrayInitWithZoneAndStaticCapacity(a, _zone, 64, i);
#endif
  lockNCTable(TABLE);

  /*
   * Find all the observers that specified neither NAME nor OBJECT.
   */
  for (o = WILDCARD = purgeCollected(WILDCARD); o != ENDOBS; o = o->next)
    {
      GSIArrayAddItem(a, (GSIArrayItem)o);
    }

  /*
   * Find the observers that specified OBJECT, but didn't specify NAME.
   */
  if (object)
    {
      n = GSIMapNodeForSimpleKey(NAMELESS, (GSIMapKey)object);
      if (n != 0)
	{
	  o = purgeCollectedFromMapNode(NAMELESS, n);
	  while (o != ENDOBS)
	    {
	      GSIArrayAddItem(a, (GSIArrayItem)o);
	      o = o->next;
	    }
	}
    }

  /*
   * Find the observers of NAME, except those observers with a non-nil OBJECT
   * that doesn't match the notification's OBJECT).
   */
  if (name)
    {
      n = GSIMapNodeForKey(NAMED, (GSIMapKey)((id)name));
      if (n)
	{
	  m = (GSIMapTable)n->value.ptr;
	}
      else
	{
	  m = 0;
	}
      if (m != 0)
	{
	  /*
	   * First, observers with a matching object.
	   */
	  n = GSIMapNodeForSimpleKey(m, (GSIMapKey)object);
	  if (n != 0)
	    {
	      o = purgeCollectedFromMapNode(m, n);
	      while (o != ENDOBS)
		{
		  GSIArrayAddItem(a, (GSIArrayItem)o);
		  o = o->next;
		}
	    }

	  if (object != nil)
	    {
	      /*
	       * Now observers with a nil object.
	       */
	      n = GSIMapNodeForSimpleKey(m, (GSIMapKey)nil);
	      if (n != 0)
		{
	          o = purgeCollectedFromMapNode(m, n);
		  while (o != ENDOBS)
		    {
		      GSIArrayAddItem(a, (GSIArrayItem)o);
		      o = o->next;
		    }
		}
	    }
	}
    }

  /*
   * Finished with the table ... we can unlock it and re-enable garbage
   * collection, safe in the knowledge that the observers we will be
   * notifying won't get collected prematurely.
   */
  unlockNCTable(TABLE);
#if	GS_WITH_GC
  [collector enable];
#endif

  /*
   * Now send all the notifications.
   */
  count = GSIArrayCount(a);
  while (count-- > 0)
    {
      o = GSIArrayItemAtIndex(a, count).ext;
      if (o->next != 0)
	{
          NS_DURING
            {
              (*o->method)(o->observer, o->selector, notification);
            }
          NS_HANDLER
            {
              NSLog(@"Problem posting notification: %@", localException);
            }
          NS_ENDHANDLER
	}
    }
  lockNCTable(TABLE);
  GSIArrayEmpty(a);
  unlockNCTable(TABLE);

  RELEASE(notification);
}


/**
 * Posts notification to all the observers that match its NAME and OBJECT.<br />
 * The GNUstep implementation calls -postNotificationName:object:userInfo: to
 * perform the actual posting.
 */
- (void) postNotification: (NSNotification*)notification
{
  if (notification == nil)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Tried to post a nil notification."];
    }
  [self _postAndRelease: RETAIN(notification)];
}

/**
 * Creates and posts a notification using the
 * -postNotificationName:object:userInfo: passing a nil user info argument.
 */
- (void) postNotificationName: (NSString*)name
		       object: (id)object
{
  [self postNotificationName: name object: object userInfo: nil];
}

/**
 * The preferred method for posting a notification.
 * <br />
 * For performance reasons, we don't wrap an exception handler round every
 * message sent to an observer.  This means that, if one observer raises
 * an exception, later observers in the lists will not get the notification.
 */
- (void) postNotificationName: (NSString*)name
		       object: (id)object
		     userInfo: (NSDictionary*)info
{
  GSNotification	*notification;

  notification = (id)NSAllocateObject(concrete, 0, NSDefaultMallocZone());
  notification->_name = [name copyWithZone: [self zone]];
  notification->_object = [object retain];
  notification->_info = [info retain];
  [self _postAndRelease: notification];
}

@end


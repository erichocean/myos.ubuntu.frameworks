/**
   NSFileManager.m

   Copyright (C) 1997-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: Feb 1997
   Updates and fixes: Richard Frith-Macdonald

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: Apr 2001
   Rewritten NSDirectoryEnumerator

   Author: Richard Frith-Macdonald <rfm@gnu.org>
   Date: Sep 2002
   Rewritten attribute handling code

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

   <title>NSFileManager class reference</title>
   $Date: 2012-03-03 01:19:41 -0800 (Sat, 03 Mar 2012) $ $Revision: 34872 $
*/

#define _FILE_OFFSET_BITS 64
/* The following define is needed for Solaris get(pw/gr)(nam/uid)_r declartions
   which default to pre POSIX declaration.  */
#define _POSIX_PTHREAD_SEMANTICS

#import "common.h"
#define	EXPOSE_NSFileManager_IVARS	1
#define	EXPOSE_NSDirectoryEnumerator_IVARS	1
#import "Foundation/NSArray.h"
#import "Foundation/NSAutoreleasePool.h"
#import "Foundation/NSData.h"
#import "Foundation/NSDate.h"
#import "Foundation/NSDictionary.h"
#import "Foundation/NSEnumerator.h"
#import "Foundation/NSException.h"
#import "Foundation/NSFileManager.h"
#import "Foundation/NSLock.h"
#import "Foundation/NSPathUtilities.h"
#import "Foundation/NSProcessInfo.h"
#import "Foundation/NSSet.h"
#import "Foundation/NSValue.h"
#import "GSPrivate.h"
#import "GNUstepBase/NSObject+GNUstepBase.h"
#import "GNUstepBase/NSString+GNUstepBase.h"

#include <string.h>
#include <stdio.h>

/* determine directory reading files */

#if defined(HAVE_DIRENT_H)
# include <dirent.h>
#elif defined(HAVE_SYS_DIR_H)
# include <sys/dir.h>
#elif defined(HAVE_SYS_NDIR_H)
# include <sys/ndir.h>
#elif defined(HAVE_NDIR_H)
# include <ndir.h>
#endif

#ifdef HAVE_WINDOWS_H
#  include <windows.h>
#endif

#if	defined(__MINGW__)
#include <stdio.h>
#include <tchar.h>
#include <wchar.h>
#include <accctrl.h>
#include <aclapi.h>
#define	WIN32ERR	((DWORD)0xFFFFFFFF)
#endif

/* determine filesystem max path length */

#if defined(_POSIX_VERSION) || defined(__WIN32__)
# if defined(__MINGW__)
#   include <sys/utime.h>
# else
#   include <utime.h>
# endif
#endif

#ifdef HAVE_SYS_CDEFS_H
# include <sys/cdefs.h>
#endif
#ifdef HAVE_SYS_SYSLIMITS_H
# include <sys/syslimits.h>
#endif
#ifdef HAVE_SYS_PARAM_H
# include <sys/param.h>		/* for MAXPATHLEN */
#endif

#ifndef PATH_MAX
# ifdef _POSIX_VERSION
#  define PATH_MAX _POSIX_PATH_MAX
# else
#  ifdef MAXPATHLEN
#   define PATH_MAX MAXPATHLEN
#  else
#   define PATH_MAX 1024
#  endif
# endif
#endif

/* determine if we have statfs struct and function */

#ifdef HAVE_SYS_VFS_H
# include <sys/vfs.h>
#endif

#ifdef HAVE_SYS_STATVFS_H
# include <sys/statvfs.h>
#endif

#ifdef HAVE_SYS_STATFS_H
# include <sys/statfs.h>
#endif

#if	defined(HAVE_SYS_FILE_H)
# include <sys/file.h>
#endif

#ifdef HAVE_SYS_MOUNT_H
#include <sys/mount.h>
#endif

#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif

#if	defined(HAVE_SYS_FCNTL_H)
#  include	<sys/fcntl.h>
#elif	defined(HAVE_FCNTL_H)
#  include	<fcntl.h>
#endif

#ifdef HAVE_PWD_H
#include <pwd.h>     /* For struct passwd */
#endif
#ifdef HAVE_GRP_H
#include <grp.h>     /* For struct group */
#endif
#ifdef HAVE_UTIME_H
# include <utime.h>
#endif

/*
 * On systems that have the O_BINARY flag, use it for a binary copy.
 */
#if defined(O_BINARY)
#define	GSBINIO	O_BINARY
#else
#define	GSBINIO	0
#endif

@interface NSDirectoryEnumerator (Local)
- (id) initWithDirectoryPath: (NSString*)path 
   recurseIntoSubdirectories: (BOOL)recurse
              followSymlinks: (BOOL)follow
                justContents: (BOOL)justContents
			 for: (NSFileManager*)mgr;
@end

/*
 * Macros to handle unichar filesystem support.
 */

#if	defined(__MINGW__)

#define	_CHMOD(A,B)	_wchmod(A,B)
#define	_CLOSEDIR(A)	_wclosedir(A)
#define	_OPENDIR(A)	_wopendir(A)
#define	_READDIR(A)	_wreaddir(A)
#define	_RENAME(A,B)	(MoveFileExW(A,B,MOVEFILE_COPY_ALLOWED|MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH)==0)?-1:0
#define	_RMDIR(A)	_wrmdir(A)
#define	_STAT(A,B)	_wstat(A,B)
#define	_UTIME(A,B)	_wutime(A,B)

#define	_CHAR		unichar
#define	_DIR		_WDIR
#define	_DIRENT		_wdirent
#define	_STATB		_stat
#define	_UTIMB		_utimbuf

#define	_NUL		L'\0'

#else

#define	_CHMOD(A,B)	chmod(A,B)
#define	_CLOSEDIR(A)	closedir(A)
#define	_OPENDIR(A)	opendir(A)
#define	_READDIR(A)	readdir(A)
#define	_RENAME(A,B)	rename(A,B)
#define	_RMDIR(A)	rmdir(A)
#define	_STAT(A,B)	stat(A,B)
#define	_UTIME(A,B)	utime(A,B)

#define	_CHAR		char
#define	_DIR		DIR
#define	_DIRENT		dirent
#define	_STATB		stat
#define	_UTIMB		utimbuf

#define	_NUL		'\0'

#endif

#define	_CCP		const _CHAR*




/*
 * GSAttrDictionary is a private NSDictionary subclass used to
 * handle file attributes efficiently ...  using lazy evaluation
 * to ensure that we only do the minimum work necessary at any time.
 */
@interface	GSAttrDictionary : NSDictionary
{
@public
  struct _STATB	statbuf;
  _CHAR		_path[0];
}
+ (NSDictionary*) attributesAt: (const _CHAR*)lpath
		  traverseLink: (BOOL)traverse;
@end

static Class	GSAttrDictionaryClass = 0;

/*
 * We also need a special enumerator class to enumerate the dictionary.
 */
@interface	GSAttrDictionaryEnumerator : NSEnumerator
{
  NSDictionary	*dictionary;
  NSEnumerator	*enumerator;
}
+ (NSEnumerator*) enumeratorFor: (NSDictionary*)d;
@end



@interface NSFileManager (PrivateMethods)

/* Copies the contents of source file to destination file. Assumes source
   and destination are regular files or symbolic links. */
- (BOOL) _copyFile: (NSString*)source
	    toFile: (NSString*)destination
	   handler: (id)handler;

/* Recursively copies the contents of source directory to destination. */
- (BOOL) _copyPath: (NSString*)source
	    toPath: (NSString*)destination
	   handler: (id)handler;

/* Recursively links the contents of source directory to destination. */
- (BOOL) _linkPath: (NSString*)source
	    toPath: (NSString*)destination
	   handler: handler;

/* encapsulates the will Process check for existence of selector. */
- (void) _sendToHandler: (id) handler
        willProcessPath: (NSString*) path;

/* methods to encapsulates setting up and calling the handler
   in case of an error */
- (BOOL) _proceedAccordingToHandler: (id) handler
                           forError: (NSString*) error
                             inPath: (NSString*) path;

- (BOOL) _proceedAccordingToHandler: (id) handler
                           forError: (NSString*) error
                             inPath: (NSString*) path
                           fromPath: (NSString*) fromPath
                             toPath: (NSString*) toPath;




@end /* NSFileManager (PrivateMethods) */

/**
 *  This is the main class for platform-independent management of the local
 *  filesystem, which allows you to read and save files, create/list
 *  directories, and move or delete files and directories.  In addition to
 *  simply listing directories, you may obtain an [NSDirectoryEnumerator]
 *  instance for recursive directory contents enumeration.
 */
@implementation NSFileManager

// Getting the default manager

static NSFileManager* defaultManager = nil;
static NSStringEncoding	defaultEncoding;

/**
 * Returns a shared default file manager which may be used throughout an
 * application.
 */
+ (NSFileManager*) defaultManager
{
  if (defaultManager == nil)
    {
      NS_DURING
	{
	  [gnustep_global_lock lock];
	  if (defaultManager == nil)
	    {
	      defaultManager = [[self alloc] init];
	    }
	  [gnustep_global_lock unlock];
	}
      NS_HANDLER
	{
	  // unlock then re-raise the exception
	  [gnustep_global_lock unlock];
	  [localException raise];
	}
      NS_ENDHANDLER
    }
  return defaultManager;
}

+ (void) initialize
{
  defaultEncoding = [NSString defaultCStringEncoding];
  GSAttrDictionaryClass = [GSAttrDictionary class];
}

- (void) dealloc
{
  TEST_RELEASE(_lastError);
  [super dealloc];
}

/**
 * Changes the current directory used for all subsequent operations.<br />
 * All non-absolute paths are interpreted relative to this directory.<br />
 * The current directory is set on a per-task basis, so the current
 * directory for other file manager instances will also be changed
 * by this method.
 */
- (BOOL) changeCurrentDirectoryPath: (NSString*)path
{
  static Class	bundleClass = 0;
  const _CHAR	*lpath = [self fileSystemRepresentationWithPath: path];

  /*
   * On some systems the only way NSBundle can determine the path to the
   * executable is by searching for it ... so it needs to know what was
   * the current directory at launch time ... so we must make sure it is
   * initialised before we change the current directory.
   */
  if (bundleClass == 0)
    {
      bundleClass = [NSBundle class];
    }
#if defined(__MINGW__)
  return SetCurrentDirectoryW(lpath) == TRUE ? YES : NO;
#else
  return (chdir(lpath) == 0) ? YES : NO;
#endif
}

/**
 * Change the attributes of the file at path to those specified.<br />
 * Returns YES if all requested changes were made (or if the dictionary
 * was nil or empty, so no changes were requested), NO otherwise.<br />
 * On failure, some of the requested changes may have taken place.<br />
 */
- (BOOL) changeFileAttributes: (NSDictionary*)attributes atPath: (NSString*)path
{
  const _CHAR	*lpath = 0;
  unsigned long	num;
  NSString	*str;
  NSDate	*date;
  BOOL		allOk = YES;

  if (attributes == nil)
    {
      return YES;
    }
  lpath = [defaultManager fileSystemRepresentationWithPath: path];

#ifndef __MINGW__
  if (object_getClass(attributes) == GSAttrDictionaryClass)
    {
      num = ((GSAttrDictionary*)attributes)->statbuf.st_uid;
    }
  else
    {
      NSNumber	*tmpNum = [attributes fileOwnerAccountID];

      num = tmpNum ? [tmpNum unsignedLongValue] : NSNotFound;
    }
  if (num != NSNotFound)
    {
      if (chown(lpath, num, -1) != 0)
	{
	  allOk = NO;
	  str = [NSString stringWithFormat:
	    @"Unable to change NSFileOwnerAccountID to '%u' - %@",
	    num, [NSError _last]];
	  ASSIGN(_lastError, str);
	}
    }
  else
    {
      if ((str = [attributes fileOwnerAccountName]) != nil)
	{
	  BOOL	ok = NO;
#ifdef HAVE_PWD_H
#if     defined(HAVE_GETPWNAM_R)
	  struct passwd pw;
	  struct passwd *p;
          char buf[BUFSIZ*10];

	  if (getpwnam_r([str cStringUsingEncoding: defaultEncoding],
            &pw, buf, sizeof(buf), &p) == 0)
	    {
	      ok = (chown(lpath, pw.pw_uid, -1) == 0);
	      chown(lpath, -1, pw.pw_gid);
	    }
#else
#if     defined(HAVE_GETPWNAM)
	  struct passwd *pw;

          [gnustep_global_lock lock];
	  pw = getpwnam([str cStringUsingEncoding: defaultEncoding]);
	  if (pw != 0)
	    {
	      ok = (chown(lpath, pw->pw_uid, -1) == 0);
	      chown(lpath, -1, pw->pw_gid);
	    }
          [gnustep_global_lock unlock];
#endif
#endif
#endif
	  if (ok == NO)
	    {
	      allOk = NO;
	      str = [NSString stringWithFormat:
		@"Unable to change NSFileOwnerAccountName to '%@' - %@",
		str, [NSError _last]];
	      ASSIGN(_lastError, str);
	    }
	}
    }

  if (object_getClass(attributes) == GSAttrDictionaryClass)
    {
      num = ((GSAttrDictionary*)attributes)->statbuf.st_gid;
    }
  else
    {
      NSNumber	*tmpNum = [attributes fileGroupOwnerAccountID];

      num = tmpNum ? [tmpNum unsignedLongValue] : NSNotFound;
    }
  if (num != NSNotFound)
    {
      if (chown(lpath, -1, num) != 0)
	{
	  allOk = NO;
	  str = [NSString stringWithFormat:
	    @"Unable to change NSFileGroupOwnerAccountID to '%u' - %@",
	    num, [NSError _last]];
	  ASSIGN(_lastError, str);
	}
    }
  else if ((str = [attributes fileGroupOwnerAccountName]) != nil)
    {
      BOOL	ok = NO;
#ifdef HAVE_GRP_H
#ifdef HAVE_GETGRNAM_R
      struct group gp;
      struct group *p;
      char buf[BUFSIZ*10];

      if (getgrnam_r([str cStringUsingEncoding: defaultEncoding], &gp,
        buf, sizeof(buf), &p) == 0)
        {
	  if (chown(lpath, -1, gp.gr_gid) == 0)
	    ok = YES;
        }
#else
#ifdef HAVE_GETGRNAM
      struct group *gp;
      
      [gnustep_global_lock lock];
      gp = getgrnam([str cStringUsingEncoding: defaultEncoding]);
      if (gp)
	{
	  if (chown(lpath, -1, gp->gr_gid) == 0)
	    ok = YES;
	}
      [gnustep_global_lock unlock];
#endif
#endif
#endif
      if (ok == NO)
	{
	  allOk = NO;
	  str = [NSString stringWithFormat:
	    @"Unable to change NSFileGroupOwnerAccountName to '%@' - %@",
	    str, [NSError _last]];
	  ASSIGN(_lastError, str);
	}
    }
#endif	/* __MINGW__ */

  num = [attributes filePosixPermissions];
  if (num != NSNotFound)
    {
      if (_CHMOD(lpath, num) != 0)
	{
	  allOk = NO;
	  str = [NSString stringWithFormat:
	    @"Unable to change NSFilePosixPermissions to '%o' - %@",
	    num, [NSError _last]];
	  ASSIGN(_lastError, str);
	}
    }

  date = [attributes fileModificationDate];
  if (date != nil)
    {
      BOOL		ok = NO;
      struct _STATB	sb;

#if  defined(__WIN32__) || defined(_POSIX_VERSION)
      struct _UTIMB ub;
#else
      time_t ub[2];
#endif

      if (_STAT(lpath, &sb) != 0)
	{
	  ok = NO;
	}
#if  defined(__WIN32__)
      else if (sb.st_mode & _S_IFDIR)
	{
	  ok = YES;	// Directories don't have modification times.
	}
#endif
      else
	{
#if  defined(__WIN32__) || defined(_POSIX_VERSION)
	  ub.actime = sb.st_atime;
	  ub.modtime = [date timeIntervalSince1970];
	  ok = (_UTIME(lpath, &ub) == 0);
#else
	  ub[0] = sb.st_atime;
	  ub[1] = [date timeIntervalSince1970];
	  ok = (_UTIME(lpath, ub) == 0);
#endif
	}
      if (ok == NO)
	{
	  allOk = NO;
	  str = [NSString stringWithFormat:
	    @"Unable to change NSFileModificationDate to '%@' - %@",
	    date, [NSError _last]];
	  ASSIGN(_lastError, str);
	}
    }

  return allOk;
}

/**
 * Returns an array of path components suitably modified for display
 * to the end user.  This modification may render the returned strings
 * unusable for path manipulation, so you should work with two arrays ...
 * one returned by this method (for display to the user), and a
 * parallel one returned by [NSString-pathComponents] (for path
 * manipulation).
 */
- (NSArray*) componentsToDisplayForPath: (NSString*)path
{
  return [path pathComponents];
}

/**
 * Reads the file at path an returns its contents as an NSData object.<br />
 * If an error occurs or if path specifies a directory etc then nil is
 * returned.
 */
- (NSData*) contentsAtPath: (NSString*)path
{
  return [NSData dataWithContentsOfFile: path];
}

/**
 * Returns YES if the contents of the file or directory at path1 are the same
 * as those at path2.<br />
 * If path1 and path2 are files, this is a simple comparison.  If they are
 * directories, the contents of the files in those subdirectories are
 * compared recursively.<br />
 * Symbolic links are not followed.<br />
 * A comparison checks first file identity, then size, then content.
 */
- (BOOL) contentsEqualAtPath: (NSString*)path1 andPath: (NSString*)path2
{
  NSDictionary	*d1;
  NSDictionary	*d2;
  NSString	*t;

  if ([path1 isEqual: path2])
    return YES;
  d1 = [self fileAttributesAtPath: path1 traverseLink: NO];
  d2 = [self fileAttributesAtPath: path2 traverseLink: NO];
  t = [d1 fileType];
  if ([t isEqual: [d2 fileType]] == NO)
    {
      return NO;
    }
  if ([t isEqual: NSFileTypeRegular])
    {
      if ([d1 fileSize] == [d2 fileSize])
	{
	  NSData	*c1 = [NSData dataWithContentsOfFile: path1];
	  NSData	*c2 = [NSData dataWithContentsOfFile: path2];

	  if ([c1 isEqual: c2])
	    {
	      return YES;
	    }
	}
      return NO;
    }
  else if ([t isEqual: NSFileTypeDirectory])
    {
      NSArray	*a1 = [self directoryContentsAtPath: path1];
      NSArray	*a2 = [self directoryContentsAtPath: path2];
      unsigned	index, count = [a1 count];
      BOOL	ok = YES;

      if ([a1 isEqual: a2] == NO)
	{
	  return NO;
	}
      for (index = 0; ok == YES && index < count; index++)
	{
	  NSString	*n = [a1 objectAtIndex: index];
	  NSString	*p1;
	  NSString	*p2;
	  NSAutoreleasePool *pool = [NSAutoreleasePool new];

	  p1 = [path1 stringByAppendingPathComponent: n];
	  p2 = [path2 stringByAppendingPathComponent: n];
	  d1 = [self fileAttributesAtPath: p1 traverseLink: NO];
	  d2 = [self fileAttributesAtPath: p2 traverseLink: NO];
	  t = [d1 fileType];
	  if ([t isEqual: [d2 fileType]] == NO)
	    {
	      ok = NO;
	    }
	  else if ([t isEqual: NSFileTypeDirectory])
	    {
	      ok = [self contentsEqualAtPath: p1 andPath: p2];
	    }
	  [pool drain];
	}
      return ok;
    }
  else
    {
      return YES;
    }
}

- (NSArray*) contentsOfDirectoryAtPath: (NSString*)path error: (NSError**)error
{
  return [self directoryContentsAtPath: path];
}

/**
 * Creates a new directory and all intermediate directories
 * if flag is YES, creates only the last directory in the path
 * if flag is NO.  The directory is created with the attributes
 * specified in attributes and any error is returned in error.<br />
 * returns YES on success, NO on failure.
 */
- (BOOL) createDirectoryAtPath: (NSString *)path
   withIntermediateDirectories: (BOOL)flag
		    attributes: (NSDictionary *)attributes
			 error: (NSError **) error
{
  BOOL result = NO;

  if (flag == YES)
    {
      NSEnumerator *paths = [[path pathComponents] objectEnumerator];
      NSString *path = nil;
      NSString *dir = [NSString string];

      while ((path = (NSString *)[paths nextObject]) != nil)
	{
	  dir = [dir stringByAppendingPathComponent: path];
	  result = [self createDirectoryAtPath: dir
			 attributes: attributes];
	}
    }
  else
    {
      BOOL isDir;

      if ([self fileExistsAtPath: [path stringByDeletingLastPathComponent]
	isDirectory: &isDir] && isDir)
        {
          result = [self createDirectoryAtPath: path
                                    attributes: attributes];
        }
      else
        {
          result = NO;  
          ASSIGN(_lastError, @"Could not create directory - intermediate paths did not exist or were not a directory");
        }
    }  

  if (error != NULL)
    {
      *error = [NSError _last];
    }
  return result;
}

/**
 * Creates a new directory, and sets its attributes as specified.<br />
 * Creates other directories in the path as necessary.<br />
 * Returns YES on success, NO on failure.
 */
- (BOOL) createDirectoryAtPath: (NSString*)path
		    attributes: (NSDictionary*)attributes
{
#if defined(__MINGW__)
  NSEnumerator	*paths = [[path pathComponents] objectEnumerator];
  NSString	*subPath;
  NSString	*completePath = nil;
#else
  const char	*lpath;
  char		dirpath[PATH_MAX+1];
  struct _STATB	statbuf;
  int		len, cur;
  NSDictionary	*needChown = nil;
#endif

  /* This is consistent with MacOSX - just return NO for an invalid path. */
  if ([path length] == 0)
    return NO;

#if defined(__MINGW__)
  while ((subPath = [paths nextObject]))
    {
      BOOL isDir = NO;

      if (completePath == nil)
	completePath = subPath;
      else
	completePath = [completePath stringByAppendingPathComponent: subPath];

      if ([self fileExistsAtPath: completePath isDirectory: &isDir])
	{
	  if (!isDir)
	    NSLog(@"WARNING: during creation of directory %@:"
		  @" sub path %@ exists, but is not a directory !",
		  path, completePath);
        }
      else
	{
	  const _CHAR *lpath;

	  lpath = [self fileSystemRepresentationWithPath: completePath];
	  if (CreateDirectoryW(lpath, 0) == FALSE)
	    {
	      return NO;
	    }
        }
    }

#else

  /*
   * If there is no file owner specified, and we are running setuid to
   * root, then we assume we need to change ownership to correct user.
   */
  if (attributes == nil || ([attributes fileOwnerAccountID] == nil
    && [attributes fileOwnerAccountName] == nil))
    {
      if (geteuid() == 0 && [@"root" isEqualToString: NSUserName()] == NO)
	{
	  needChown = [NSDictionary dictionaryWithObjectsAndKeys:
	    NSFileOwnerAccountName, NSUserName(), nil];
	}
    }
  lpath = [self fileSystemRepresentationWithPath: path];
  len = strlen(lpath);
  if (len > PATH_MAX) // name too long
    {
      ASSIGN(_lastError, @"Could not create directory - name too long");
      return NO;
    }

  if (strcmp(lpath, "/") == 0 || len == 0) // cannot use "/" or ""
    {
      ASSIGN(_lastError, @"Could not create directory - no name given");
      return NO;
    }

  strncpy(dirpath, lpath, len);
  dirpath[len] = '\0';
  if (dirpath[len-1] == '/')
    dirpath[len-1] = '\0';
  cur = 0;

  do
    {
      // find next '/'
      while (dirpath[cur] != '/' && cur < len)
	cur++;
      // if first char is '/' then again; (cur == len) -> last component
      if (cur == 0)
	{
	  cur++;
	  continue;
	}
      // check if path from 0 to cur is valid
      dirpath[cur] = '\0';
      if (_STAT(dirpath, &statbuf) == 0)
	{
	  if (cur == len)
	    {
	      ASSIGN(_lastError,
		@"Could not create directory - already exists");
	      return NO;
	    }
	}
      else
	{
	  // make new directory
	  if (mkdir(dirpath, 0777) != 0)
	    {
	      NSString	*s;

	      s = [NSString stringWithFormat: @"Could not create '%s' - '%@'",
		dirpath, [NSError _last]];
	      ASSIGN(_lastError, s);
	      return NO;
	    }
	  // if last directory and attributes then change
	  if (cur == len && attributes != nil)
	    {
	      if ([self changeFileAttributes: attributes
		atPath: [self stringWithFileSystemRepresentation: dirpath
			length: cur]] == NO)
		return NO;
	      if (needChown != nil)
		{
		  if ([self changeFileAttributes: needChown
		    atPath: [self stringWithFileSystemRepresentation: dirpath
		      length: cur]] == NO)
		    {
		      NSLog(@"Failed to change ownership of '%s' to '%@'",
			      dirpath, NSUserName());
		    }
		}
	      return YES;
	    }
	}
      dirpath[cur] = '/';
      cur++;
    }
  while (cur < len);

#endif /* !MINGW */

  // change attributes of last directory
  if ([attributes count] == 0)
    {
      return YES;
    }
  return [self changeFileAttributes: attributes atPath: path];
}

/**
 * Creates a new file, and sets its attributes as specified.<br />
 * Initialises the file content with the specified data.<br />
 * Returns YES on success, NO on failure.
 */
- (BOOL) createFileAtPath: (NSString*)path
		 contents: (NSData*)contents
	       attributes: (NSDictionary*)attributes
{
#if	defined(__MINGW__)
  const _CHAR *lpath = [self fileSystemRepresentationWithPath: path];
  HANDLE fh;
  DWORD	written = 0;
  DWORD	len = [contents length];
#else
  const char	*lpath;
  int	fd;
  int	len;
  int	written;
#endif

  /* This is consistent with MacOSX - just return NO for an invalid path. */
  if ([path length] == 0)
    return NO;

#if	defined(__MINGW__)
  fh = CreateFileW(lpath, GENERIC_WRITE, 0, 0, CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL, 0);
  if (fh == INVALID_HANDLE_VALUE)
    {
      return NO;
    }
  else
    {
      if (len > 0)
	{
	  WriteFile(fh, [contents bytes], len, &written, 0);
	}
      CloseHandle(fh);
      if (attributes != nil
	&& [self changeFileAttributes: attributes atPath: path] == NO)
	{
	  return NO;
	}
      return YES;
    }
#else
  lpath = [self fileSystemRepresentationWithPath: path];

  fd = open(lpath, GSBINIO|O_WRONLY|O_TRUNC|O_CREAT, 0644);
  if (fd < 0)
    {
      return NO;
    }
  if (attributes != nil
    && [self changeFileAttributes: attributes atPath: path] == NO)
    {
      close (fd);
      return NO;
    }

  /*
   * If there is no file owner specified, and we are running setuid to
   * root, then we assume we need to change ownership to correct user.
   */
  if (attributes == nil || ([attributes fileOwnerAccountID] == nil
    && [attributes fileOwnerAccountName] == nil))
    {
      if (geteuid() == 0 && [@"root" isEqualToString: NSUserName()] == NO)
	{
	  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
	    NSFileOwnerAccountName, NSUserName(), nil];
	  if (![self changeFileAttributes: attributes atPath: path])
	    {
	      NSLog(@"Failed to change ownership of '%@' to '%@'",
		path, NSUserName());
	    }
	}
    }
  len = [contents length];
  if (len > 0)
    {
      written = write(fd, [contents bytes], len);
    }
  else
    {
      written = 0;
    }
  close (fd);
#endif
  return written == len;
}

/**
 * Returns the current working directory used by all instance of the file
 * manager in the current task.
 */
- (NSString*) currentDirectoryPath
{
  NSString *currentDir = nil;

#if defined(__MINGW__)
  int len = GetCurrentDirectoryW(0, 0);
  if (len > 0)
    {
      _CHAR *lpath = (_CHAR*)calloc(len+10,sizeof(_CHAR));

      if (lpath != 0)
	{
	  if (GetCurrentDirectoryW(len, lpath)>0)
	    {
	      NSString	*path;

	      // Windows may count the trailing nul ... we don't want to.
	      if (len > 0 && lpath[len] == 0) len--;
	      path = [NSString stringWithCharacters: lpath length: len];
	      currentDir = path;
	    }
	  free(lpath);
	}
    }
#else
  char path[PATH_MAX];
#ifdef HAVE_GETCWD
  if (getcwd(path, PATH_MAX-1) == 0)
    return nil;
#else
  if (getwd(path) == 0)
    return nil;
#endif /* HAVE_GETCWD */
  currentDir = [self stringWithFileSystemRepresentation: path
						 length: strlen(path)];
#endif /* !MINGW */

  return currentDir;
}

/**
 * Copies the file or directory at source to destination, using a
 * handler object which should respond to
 * [NSObject(NSFileManagerHandler)-fileManager:willProcessPath:] and
 * [NSObject(NSFileManagerHandler)-fileManager:shouldProceedAfterError:]
 * messages.<br />
 * Will not copy to a destination which already exists.
 */
- (BOOL) copyPath: (NSString*)source
	   toPath: (NSString*)destination
	  handler: (id)handler
{
  NSDictionary	*attrs;
  NSString	*fileType;

  if ([self fileExistsAtPath: destination] == YES)
    {
      return NO;
    }
  attrs = [self fileAttributesAtPath: source traverseLink: NO];
  if (attrs == nil)
    {
      return NO;
    }
  fileType = [attrs fileType];
  if ([fileType isEqualToString: NSFileTypeDirectory] == YES)
    {
      NSMutableDictionary	*mattrs;

      /* If destination directory is a descendant of source directory copying
	  isn't possible. */
      if ([[destination stringByAppendingString: @"/"]
	hasPrefix: [source stringByAppendingString: @"/"]])
	{
	  return NO;
	}

      [self _sendToHandler: handler willProcessPath: destination];

      /*
       * Don't attempt to retain ownership of copy ... we want the copy
       * to be owned by the current user.
       */
      mattrs = [attrs mutableCopy];
      [mattrs removeObjectForKey: NSFileOwnerAccountID];
      [mattrs removeObjectForKey: NSFileGroupOwnerAccountID];
      [mattrs removeObjectForKey: NSFileGroupOwnerAccountName];
      [mattrs setObject: NSUserName() forKey: NSFileOwnerAccountName];
      attrs = AUTORELEASE(mattrs);

      if ([self createDirectoryAtPath: destination attributes: attrs] == NO)
	{
          return [self _proceedAccordingToHandler: handler
					 forError: _lastError
					   inPath: destination
					 fromPath: source
					   toPath: destination];
	}

      if ([self _copyPath: source toPath: destination handler: handler] == NO)
	{
	  return NO;
	}
    }
  else if ([fileType isEqualToString: NSFileTypeSymbolicLink] == YES)
    {
      NSString	*path;
      BOOL	result;

      [self _sendToHandler: handler willProcessPath: source];

      path = [self pathContentOfSymbolicLinkAtPath: source];
      result = [self createSymbolicLinkAtPath: destination pathContent: path];
      if (result == NO)
	{
          result = [self _proceedAccordingToHandler: handler
					   forError: @"cannot link to file"
					     inPath: source
					   fromPath: source
					     toPath: destination];

	  if (result == NO)
	    {
	      return NO;
	    }
	}
    }
  else
    {
      [self _sendToHandler: handler willProcessPath: source];

      if ([self _copyFile: source toFile: destination handler: handler] == NO)
	{
	  return NO;
	}
    }
  [self changeFileAttributes: attrs atPath: destination];
  return YES;
}

- (BOOL) copyItemAtPath: (NSString*)src
		 toPath: (NSString*)dst
		  error: (NSError**)error
{
  BOOL	result;

  result = [self copyPath: src toPath: dst handler: nil];
  return result;
}

/**
 * Moves the file or directory at source to destination, using a
 * handler object which should respond to
 * [NSObject(NSFileManagerHandler)-fileManager:willProcessPath:] and
 * [NSObject(NSFileManagerHandler)-fileManager:shouldProceedAfterError:]
 * messages.
 * Will not move to a destination which already exists.<br />
 */
- (BOOL) movePath: (NSString*)source
	   toPath: (NSString*)destination
	  handler: (id)handler
{
  BOOL		sourceIsDir;
  BOOL		fileExists;
  NSString	*destinationParent;
  unsigned int	sourceDevice;
  unsigned int	destinationDevice;
  const _CHAR	*sourcePath;
  const _CHAR	*destPath;

  sourcePath = [self fileSystemRepresentationWithPath: source];
  destPath = [self fileSystemRepresentationWithPath: destination];

  if ([self fileExistsAtPath: destination] == YES)
    {
      return NO;
    }
  fileExists = [self fileExistsAtPath: source isDirectory: &sourceIsDir];
  if (!fileExists)
    {
      return NO;
    }

  /* Check to see if the source and destination's parent are on the same
     physical device so we can perform a rename syscall directly. */
  sourceDevice = [[self fileSystemAttributesAtPath: source] fileSystemNumber];
  destinationParent = [destination stringByDeletingLastPathComponent];
  if ([destinationParent isEqual: @""])
    destinationParent = @".";
  destinationDevice
    = [[self fileSystemAttributesAtPath: destinationParent] fileSystemNumber];

  if (sourceDevice != destinationDevice)
    {
      /* If destination directory is a descendant of source directory moving
	  isn't possible. */
      if (sourceIsDir && [[destination stringByAppendingString: @"/"]
	hasPrefix: [source stringByAppendingString: @"/"]])
	{
	  return NO;
	}

      if ([self copyPath: source toPath: destination handler: handler])
	{
	  NSDictionary	*attributes;

	  attributes = [self fileAttributesAtPath: source
				     traverseLink: NO];
	  [self changeFileAttributes: attributes atPath: destination];
	  return [self removeFileAtPath: source handler: handler];
	}
      else
	{
	  return NO;
	}
    }
  else
    {
      /* source and destination are on the same device so we can simply
	 invoke rename on source. */
      [self _sendToHandler: handler willProcessPath: source];

      if (_RENAME (sourcePath, destPath) == -1)
	{
          return [self _proceedAccordingToHandler: handler
					 forError: @"cannot move file"
					   inPath: source
					 fromPath: source
					   toPath: destination];
	}
      return YES;
    }

  return NO;
}

- (BOOL) moveItemAtPath: (NSString*)src
		 toPath: (NSString*)dst
		  error: (NSError**)error
{
  BOOL	result;

  result = [self movePath: src toPath: dst handler: nil];
  return result;
}

/**
 * <p>Links the file or directory at source to destination, using a
 * handler object which should respond to
 * [NSObject(NSFileManagerHandler)-fileManager:willProcessPath:] and
 * [NSObject(NSFileManagerHandler)-fileManager:shouldProceedAfterError:]
 * messages.
 * </p>
 * <p>If the destination is a directory, the source path is linked
 * into that directory, otherwise the destination must not exist,
 * but its parent directory must exist and the source will be linked
 * into the parent as the name specified by the destination.
 * </p>
 * <p>If the source is a symbolic link, it is copied to the destination.<br />
 * If the source is a directory, it is copied to the destination and its
 * contents are linked into the new directory.<br />
 * Otherwise, a hard link is made from the destination to the source.
 * </p>
 */
- (BOOL) linkPath: (NSString*)source
	   toPath: (NSString*)destination
	  handler: (id)handler
{
#ifdef HAVE_LINK
  NSDictionary	*attrs;
  NSString	*fileType;
  BOOL		isDir;

  if ([self fileExistsAtPath: destination isDirectory: &isDir] == YES
    && isDir == YES)
    {
      destination = [destination stringByAppendingPathComponent:
	[source lastPathComponent]];
    }

  attrs = [self fileAttributesAtPath: source traverseLink: NO];
  if (attrs == nil)
    {
      return NO;
    }

  [self _sendToHandler: handler willProcessPath: destination];

  fileType = [attrs fileType];
  if ([fileType isEqualToString: NSFileTypeDirectory] == YES)
    {
      /* If destination directory is a descendant of source directory linking
	  isn't possible because of recursion. */
      if ([[destination stringByAppendingString: @"/"]
	hasPrefix: [source stringByAppendingString: @"/"]])
	{
	  return NO;
	}

      if ([self createDirectoryAtPath: destination attributes: attrs] == NO)
	{
          return [self _proceedAccordingToHandler: handler
					 forError: _lastError
					   inPath: destination
					 fromPath: source
					   toPath: destination];
	}

      if ([self _linkPath: source toPath: destination handler: handler] == NO)
	{
	  return NO;
	}
    }
  else if ([fileType isEqual: NSFileTypeSymbolicLink])
    {
      NSString	*path;

      path = [self pathContentOfSymbolicLinkAtPath: source];
      if ([self createSymbolicLinkAtPath: destination
			     pathContent: path] == NO)
	{
	  if ([self _proceedAccordingToHandler: handler
				      forError: @"cannot create symbolic link"
					inPath: source
				      fromPath: source
					toPath: destination] == NO)
	    {
	      return NO;
	    }
	}
    }
  else
    {
      if (link([self fileSystemRepresentationWithPath: source],
	[self fileSystemRepresentationWithPath: destination]) < 0)
	{
	  if ([self _proceedAccordingToHandler: handler
				      forError: @"cannot create hard link"
					inPath: source
				      fromPath: source
					toPath: destination] == NO)
	    {
	      return NO;
	    }
	}
    }
  [self changeFileAttributes: attrs atPath: destination];
  return YES;
#else
  return NO;	// Links not supported on this platform
#endif
}

/**
 * Removes the file or directory at path, using a
 * handler object which should respond to
 * [NSObject(NSFileManagerHandler)-fileManager:willProcessPath:] and
 * [NSObject(NSFileManagerHandler)-fileManager:shouldProceedAfterError:]
 * messages.
 */
- (BOOL) removeFileAtPath: (NSString*)path
		  handler: handler
{
  BOOL		is_dir;
  const _CHAR	*lpath;

  if ([path isEqualToString: @"."] || [path isEqualToString: @".."])
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Attempt to remove illegal path"];
    }

  [self _sendToHandler: handler willProcessPath: path];

  lpath = [self fileSystemRepresentationWithPath: path];
  if (lpath == 0 || *lpath == 0)
    {
      return NO;
    }
  else
    {
#if defined(__MINGW__)
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
      if (res & FILE_ATTRIBUTE_DIRECTORY)
	{
	  is_dir = YES;
	}
      else
	{
	  is_dir = NO;
	}
#else
      struct _STATB statbuf;

      if (lstat(lpath, &statbuf) != 0)
	{
	  return NO;
	}
      is_dir = ((statbuf.st_mode & S_IFMT) == S_IFDIR);
#endif /* MINGW */
    }

  if (!is_dir)
    {
#if defined(__MINGW__)
      if (DeleteFileW(lpath) == FALSE)
#else
      if (unlink(lpath) < 0)
#endif
	{
	  NSString	*message = [[NSError _last] localizedDescription];

	  return [self _proceedAccordingToHandler: handler
					 forError: message
					   inPath: path];
	}
      else
	{
	  return YES;
	}
    }
  else
    {
      NSArray   *contents = [self directoryContentsAtPath: path];
      unsigned	count = [contents count];
      unsigned	i;

      for (i = 0; i < count; i++)
	{
	  NSString		*item;
	  NSString		*next;
	  BOOL			result;
	  NSAutoreleasePool	*arp = [NSAutoreleasePool new];

	  item = [contents objectAtIndex: i];
	  next = [path stringByAppendingPathComponent: item];
	  result = [self removeFileAtPath: next handler: handler];
	  [arp drain];
	  if (result == NO)
	    {
	      return NO;
	    }
	}

      if (_RMDIR([self fileSystemRepresentationWithPath: path]) < 0)
	{
	  NSString	*message = [[NSError _last] localizedDescription];

	  return [self _proceedAccordingToHandler: handler
					 forError: message
					   inPath: path];
	}
      else
	{
	  return YES;
	}
    }
}

- (BOOL) removeItemAtPath: (NSString*)path
		    error: (NSError**)error
{
  BOOL  result;

  result = [self removeFileAtPath: path handler: nil];
  return result;
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path.
 */
- (BOOL) fileExistsAtPath: (NSString*)path
{
  return [self fileExistsAtPath: path isDirectory: 0];
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path.<br />
 * If the isDirectory argument is not a nul pointer, stores a flag
 * in the location it points to, indicating whether the file is a
 * directory or not.<br />
 */
- (BOOL) fileExistsAtPath: (NSString*)path isDirectory: (BOOL*)isDirectory
{
  const _CHAR *lpath = [self fileSystemRepresentationWithPath: path];

  if (isDirectory != 0)
    {
      *isDirectory = NO;
    }

  if (lpath == 0 || *lpath == _NUL)
    {
      return NO;
    }

#if defined(__MINGW__)
    {
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
      if (isDirectory != 0)
	{
	  if (res & FILE_ATTRIBUTE_DIRECTORY)
	    {
	      *isDirectory = YES;
	    }
	}
      return YES;
    }
#else
    {
      struct _STATB statbuf;

      if (_STAT(lpath, &statbuf) != 0)
	{
	  return NO;
	}

      if (isDirectory)
	{
	  if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
	    {
	      *isDirectory = YES;
	    }
	}

      return YES;
    }
#endif /* MINGW */
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path
 * and is readable.
 */
- (BOOL) isReadableFileAtPath: (NSString*)path
{
  const _CHAR* lpath = [self fileSystemRepresentationWithPath: path];

  if (lpath == 0 || *lpath == _NUL)
    {
      return NO;
    }

#if defined(__MINGW__)
    {
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
      return YES;
    }
#else
    {
      if (access(lpath, R_OK) == 0)
	{
	  return YES;
	}
      return NO;
    }
#endif
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path
 * and is writable.
 */
- (BOOL) isWritableFileAtPath: (NSString*)path
{
  const _CHAR* lpath = [self fileSystemRepresentationWithPath: path];

  if (lpath == 0 || *lpath == _NUL)
    {
      return NO;
    }

#if defined(__MINGW__)
    {
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
      if (res & FILE_ATTRIBUTE_READONLY)
	{
	  return NO;
	}
      return YES;
    }
#else
    {
      if (access(lpath, W_OK) == 0)
	{
	  return YES;
	}
      return NO;
    }
#endif
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path
 * and is executable (if a directory is executable, you can access its
 * contents).
 */
- (BOOL) isExecutableFileAtPath: (NSString*)path
{
  const _CHAR* lpath = [self fileSystemRepresentationWithPath: path];

  if (lpath == 0 || *lpath == _NUL)
    {
      return NO;
    }

#if defined(__MINGW__)
    {
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
	// TODO: Actually should check all extensions in env var PATHEXT
      if ([[[path pathExtension] lowercaseString] isEqualToString: @"exe"])
	{
	  return YES;
	}
      /* FIXME: On unix, directory accessible == executable, so we simulate that
      here for Windows. Is there a better check for directory access? */
      if (res & FILE_ATTRIBUTE_DIRECTORY)
	{
	  return YES;
	}
      return NO;
    }
#else
    {
      if (access(lpath, X_OK) == 0)
	{
	  return YES;
	}
      return NO;
    }
#endif
}

/**
 * Returns YES if a file (or directory etc) exists at the specified path
 * and is deletable.
 */
- (BOOL) isDeletableFileAtPath: (NSString*)path
{
  const _CHAR* lpath = [self fileSystemRepresentationWithPath: path];

  if (lpath == 0 || *lpath == _NUL)
    {
      return NO;
    }

#if defined(__MINGW__)
      // TODO - handle directories
    {
      DWORD res;

      res = GetFileAttributesW(lpath);

      if (res == WIN32ERR)
	{
	  return NO;
	}
      return (res & FILE_ATTRIBUTE_READONLY) ? NO : YES;
    }
#else
    {
      // TODO - handle directories
      path = [path stringByDeletingLastPathComponent];
      if ([path length] == 0)
	{
	  path = @".";
	}
      lpath = [self fileSystemRepresentationWithPath: path];

      if (access(lpath, X_OK | W_OK) == 0)
	{
	  return YES;
	}
      return NO;
    }
#endif
}


/**
 * If a file (or directory etc) exists at the specified path, and can be
 * queried for its attributes, this method returns a dictionary containing
 * the various attributes of that file.  Otherwise nil is returned.<br />
 * If the flag is NO and the file is a symbolic link, the attributes of
 * the link itself (rather than the file it points to) are returned.<br />
 * <p>
 *   The dictionary keys for attributes are -
 * </p>
 * <deflist>
 *   <term><code>NSFileAppendOnly</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileCreationDate</code></term>
 *   <desc>NSDate when the file was created (if supported)</desc>
 *   <term><code>NSFileDeviceIdentifier</code></term>
 *   <desc>NSNumber (identifies the device on which the file is stored)</desc>
 *   <term><code>NSFileExtensionHidden</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileGroupOwnerAccountName</code></term>
 *   <desc>NSString name of the file group</desc>
 *   <term><code>NSFileGroupOwnerAccountID</code></term>
 *   <desc>NSNumber ID of the file group</desc>
 *   <term><code>NSFileHFSCreatorCode</code></term>
 *   <desc>NSNumber not used</desc>
 *   <term><code>NSFileHFSTypeCode</code></term>
 *   <desc>NSNumber not used</desc>
 *   <term><code>NSFileImmutable</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileModificationDate</code></term>
 *   <desc>NSDate when the file was last modified</desc>
 *   <term><code>NSFileOwnerAccountName</code></term>
 *   <desc>NSString name of the file owner</desc>
 *   <term><code>NSFileOwnerAccountID</code></term>
 *   <desc>NSNumber ID of the file owner</desc>
 *   <term><code>NSFilePosixPermissions</code></term>
 *   <desc>NSNumber posix access permissions mask</desc>
 *   <term><code>NSFileReferenceCount</code></term>
 *   <desc>NSNumber number of links to this file</desc>
 *   <term><code>NSFileSize</code></term>
 *   <desc>NSNumber size of the file in bytes</desc>
 *   <term><code>NSFileSystemFileNumber</code></term>
 *   <desc>NSNumber the identifier for the file on the filesystem</desc>
 *   <term><code>NSFileSystemNumber</code></term>
 *   <desc>NSNumber the filesystem on which the file is stored</desc>
 *   <term><code>NSFileType</code></term>
 *   <desc>NSString the type of file</desc>
 * </deflist>
 * <p>
 *   The [NSDictionary] class also has a set of convenience accessor methods
 *   which enable you to get at file attribute information more efficiently
 *   than using the keys above to extract it.  You should generally
 *   use the accessor methods where they are available.
 * </p>
 * <list>
 *   <item>[NSDictionary(NSFileAttributes)-fileCreationDate]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileExtensionHidden]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileHFSCreatorCode]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileHFSTypeCode]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileIsAppendOnly]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileIsImmutable]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSize]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileType]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileOwnerAccountName]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileOwnerAccountID]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileGroupOwnerAccountName]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileGroupOwnerAccountID]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileModificationDate]</item>
 *   <item>[NSDictionary(NSFileAttributes)-filePosixPermissions]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSystemNumber]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSystemFileNumber]</item>
 * </list>
 */
- (NSDictionary*) fileAttributesAtPath: (NSString*)path traverseLink: (BOOL)flag
{
  NSDictionary	*d;

  d = [GSAttrDictionaryClass attributesAt:
    [self fileSystemRepresentationWithPath: path] traverseLink: flag];
  return d;
}

/**
 * If a file (or directory etc) exists at the specified path, and can be
 * queried for its attributes, this method returns a dictionary containing
 * the various attributes of that file.  Otherwise nil is returned.<br />
 * If an error occurs, error describes the problem.
 * Pass NULL if you do not want error information.
 * <p>
 *   The dictionary keys for attributes are -
 * </p>
 * <deflist>
 *   <term><code>NSFileAppendOnly</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileCreationDate</code></term>
 *   <desc>NSDate when the file was created (if supported)</desc>
 *   <term><code>NSFileDeviceIdentifier</code></term>
 *   <desc>NSNumber (identifies the device on which the file is stored)</desc>
 *   <term><code>NSFileExtensionHidden</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileGroupOwnerAccountName</code></term>
 *   <desc>NSString name of the file group</desc>
 *   <term><code>NSFileGroupOwnerAccountID</code></term>
 *   <desc>NSNumber ID of the file group</desc>
 *   <term><code>NSFileHFSCreatorCode</code></term>
 *   <desc>NSNumber not used</desc>
 *   <term><code>NSFileHFSTypeCode</code></term>
 *   <desc>NSNumber not used</desc>
 *   <term><code>NSFileImmutable</code></term>
 *   <desc>NSNumber ... boolean</desc>
 *   <term><code>NSFileModificationDate</code></term>
 *   <desc>NSDate when the file was last modified</desc>
 *   <term><code>NSFileOwnerAccountName</code></term>
 *   <desc>NSString name of the file owner</desc>
 *   <term><code>NSFileOwnerAccountID</code></term>
 *   <desc>NSNumber ID of the file owner</desc>
 *   <term><code>NSFilePosixPermissions</code></term>
 *   <desc>NSNumber posix access permissions mask</desc>
 *   <term><code>NSFileReferenceCount</code></term>
 *   <desc>NSNumber number of links to this file</desc>
 *   <term><code>NSFileSize</code></term>
 *   <desc>NSNumber size of the file in bytes</desc>
 *   <term><code>NSFileSystemFileNumber</code></term>
 *   <desc>NSNumber the identifier for the file on the filesystem</desc>
 *   <term><code>NSFileSystemNumber</code></term>
 *   <desc>NSNumber the filesystem on which the file is stored</desc>
 *   <term><code>NSFileType</code></term>
 *   <desc>NSString the type of file</desc>
 * </deflist>
 * <p>
 *   The [NSDictionary] class also has a set of convenience accessor methods
 *   which enable you to get at file attribute information more efficiently
 *   than using the keys above to extract it.  You should generally
 *   use the accessor methods where they are available.
 * </p>
 * <list>
 *   <item>[NSDictionary(NSFileAttributes)-fileCreationDate]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileExtensionHidden]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileHFSCreatorCode]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileHFSTypeCode]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileIsAppendOnly]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileIsImmutable]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSize]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileType]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileOwnerAccountName]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileOwnerAccountID]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileGroupOwnerAccountName]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileGroupOwnerAccountID]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileModificationDate]</item>
 *   <item>[NSDictionary(NSFileAttributes)-filePosixPermissions]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSystemNumber]</item>
 *   <item>[NSDictionary(NSFileAttributes)-fileSystemFileNumber]</item>
 * </list>
 */
- (NSDictionary*) attributesOfItemAtPath: (NSString*)path
				   error: (NSError**)error
{
  NSDictionary	*d;
  
  d = [GSAttrDictionaryClass attributesAt:
    [self fileSystemRepresentationWithPath: path] traverseLink: NO];
  
  if (error != NULL)
    {
      if (nil == d)
	{
	  *error = [NSError _last];
	}
      else
	{
	  *error = nil;
	}
    }
  
  return d;
}

/**
 * Returns a dictionary containing the filesystem attributes for the
 * specified path (or nil if the path is not valid).<br />
 * <deflist>
 *   <term><code>NSFileSystemSize</code></term>
 *   <desc>NSNumber the size of the filesystem in bytes</desc>
 *   <term><code>NSFileSystemFreeSize</code></term>
 *   <desc>NSNumber the amount of unused space on the filesystem in bytes</desc>
 *   <term><code>NSFileSystemNodes</code></term>
 *   <desc>NSNumber the number of nodes in use to store files</desc>
 *   <term><code>NSFileSystemFreeNodes</code></term>
 *   <desc>NSNumber the number of nodes available to create files</desc>
 *   <term><code>NSFileSystemNumber</code></term>
 *   <desc>NSNumber the identifying number for the filesystem</desc>
 * </deflist>
 */
- (NSDictionary*) fileSystemAttributesAtPath: (NSString*)path
{
#if defined(__MINGW__)
  unsigned long long totalsize, freesize;
  id  values[5];
  id	keys[5] = {
    NSFileSystemSize,
    NSFileSystemFreeSize,
    NSFileSystemNodes,
    NSFileSystemFreeNodes,
    NSFileSystemNumber
  };
  DWORD SectorsPerCluster, BytesPerSector, NumberFreeClusters;
  DWORD TotalNumberClusters;
  DWORD volumeSerialNumber = 0;
  const _CHAR *lpath = [self fileSystemRepresentationWithPath: path];
  _CHAR volumePathName[128];

  if (!GetVolumePathNameW(lpath, volumePathName, 128))
    {
      return nil;
    }
  GetVolumeInformationW(volumePathName, NULL, 0, &volumeSerialNumber,
    NULL, NULL, NULL, 0);

  if (!GetDiskFreeSpaceW(volumePathName, &SectorsPerCluster,
    &BytesPerSector, &NumberFreeClusters, &TotalNumberClusters))
    {
      return nil;
    }

  totalsize = (unsigned long long)TotalNumberClusters
    * (unsigned long long)SectorsPerCluster
    * (unsigned long long)BytesPerSector;
  freesize = (unsigned long long)NumberFreeClusters
    * (unsigned long long)SectorsPerCluster
    * (unsigned long long)BytesPerSector;

  values[0] = [NSNumber numberWithUnsignedLongLong: totalsize];
  values[1] = [NSNumber numberWithUnsignedLongLong: freesize];
  values[2] = [NSNumber numberWithLong: LONG_MAX];
  values[3] = [NSNumber numberWithLong: LONG_MAX];
  values[4] = [NSNumber numberWithUnsignedInt: volumeSerialNumber];

  return [NSDictionary dictionaryWithObjects: values forKeys: keys count: 5];

#else
#if defined(HAVE_SYS_VFS_H) || defined(HAVE_SYS_STATFS_H) \
  || defined(HAVE_SYS_MOUNT_H)
  struct _STATB statbuf;
#ifdef HAVE_STATVFS
  struct statvfs statfsbuf;
#else
  struct statfs statfsbuf;
#endif
  unsigned long long totalsize, freesize;
  unsigned long blocksize;
  const char* lpath = [self fileSystemRepresentationWithPath: path];

  id  values[5];
  id	keys[5] = {
    NSFileSystemSize,
    NSFileSystemFreeSize,
    NSFileSystemNodes,
    NSFileSystemFreeNodes,
    NSFileSystemNumber
  };

  if (_STAT(lpath, &statbuf) != 0)
    {
      NSDebugMLLog(@"NSFileManager", @"stat failed for '%s' ... %@",
        lpath, [NSError _last]);
      return nil;
    }
#ifdef HAVE_STATVFS
  if (statvfs(lpath, &statfsbuf) != 0)
    {
      NSDebugMLLog(@"NSFileManager", @"statvfs failed for '%s' ... %@",
        lpath, [NSError _last]);
      return nil;
    }
  blocksize = statfsbuf.f_frsize;
#else
  if (statfs(lpath, &statfsbuf) != 0)
    {
      NSDebugMLLog(@"NSFileManager", @"statfs failed for '%s' ... %@",
        lpath, [NSError _last]);
      return nil;
    }
  blocksize = statfsbuf.f_bsize;
#endif

  totalsize = (unsigned long long) blocksize
    * (unsigned long long) statfsbuf.f_blocks;
  freesize = (unsigned long long) blocksize
    * (unsigned long long) statfsbuf.f_bavail;

  values[0] = [NSNumber numberWithUnsignedLongLong: totalsize];
  values[1] = [NSNumber numberWithUnsignedLongLong: freesize];
  values[2] = [NSNumber numberWithLong: statfsbuf.f_files];
  values[3] = [NSNumber numberWithLong: statfsbuf.f_ffree];
  values[4] = [NSNumber numberWithUnsignedLong: statbuf.st_dev];

  return [NSDictionary dictionaryWithObjects: values forKeys: keys count: 5];
#else
  NSLog(@"NSFileManager", @"no support for filesystem attributes");
  return nil;
#endif
#endif /* MINGW */
}

/**
 * Returns an array of the contents of the specified directory.<br />
 * The listing does <strong>not</strong> recursively list subdirectories.<br />
 * The special files '.' and '..' are not listed.<br />
 * Indicates an error by returning nil (eg. if path is not a directory or
 * it can't be read for some reason).
 */
- (NSArray*) directoryContentsAtPath: (NSString*)path
{
  NSDirectoryEnumerator	*direnum;
  NSMutableArray	*content;
  IMP			nxtImp;
  IMP			addImp;
  BOOL			is_dir;

  /*
   * See if this is a directory (don't follow links).
   */
  if ([self fileExistsAtPath: path isDirectory: &is_dir] == NO || is_dir == NO)
    {
      return nil;
    }
  /* We initialize the directory enumerator with justContents == YES,
     which tells the NSDirectoryEnumerator code that we only enumerate
     the contents non-recursively once, and exit.  NSDirectoryEnumerator
     can perform some optimisations using this assumption. */
  direnum = [[NSDirectoryEnumerator alloc] initWithDirectoryPath: path
				       recurseIntoSubdirectories: NO
						  followSymlinks: NO
						    justContents: YES
							     for: self];
  content = [NSMutableArray arrayWithCapacity: 128];

  nxtImp = [direnum methodForSelector: @selector(nextObject)];
  addImp = [content methodForSelector: @selector(addObject:)];

  while ((path = (*nxtImp)(direnum, @selector(nextObject))) != nil)
    {
      (*addImp)(content, @selector(addObject:), path);
    }
  RELEASE(direnum);

  return [content makeImmutableCopyOnFail: NO];
}

/**
 * Returns the name of the file or directory at path.  Converts it into
 * a format for display to an end user.  This may render it unusable as
 * part of a file/path name.<br />
 * For instance, if a user has elected not to see file extensions, this
 * method may return filenames with the extension removed.<br />
 * The default operation is to return the result of calling
 * [NSString-lastPathComponent] on the path.
 */
- (NSString*) displayNameAtPath: (NSString*)path
{
  return [path lastPathComponent];
}

- (NSDirectoryEnumerator*) enumeratorAtPath: (NSString*)path
{
  return AUTORELEASE([[NSDirectoryEnumerator alloc]
		       initWithDirectoryPath: path
		       recurseIntoSubdirectories: YES
		       followSymlinks: NO
		       justContents: NO
		       for: self]);
}

/**
 * Returns an array containing the (relative) paths of all the items
 * in the directory at path.<br />
 * The listing follows all subdirectories, so it can produce a very
 * large array ... use with care.
 */
- (NSArray*) subpathsAtPath: (NSString*)path
{
  NSDirectoryEnumerator	*direnum;
  NSMutableArray	*content;
  BOOL			isDir;
  IMP			nxtImp;
  IMP			addImp;

  if (![self fileExistsAtPath: path isDirectory: &isDir] || !isDir)
    {
      return nil;
    }
  direnum = [[NSDirectoryEnumerator alloc] initWithDirectoryPath: path
				       recurseIntoSubdirectories: YES
						  followSymlinks: NO
						    justContents: NO
							     for: self];
  content = [NSMutableArray arrayWithCapacity: 128];

  nxtImp = [direnum methodForSelector: @selector(nextObject)];
  addImp = [content methodForSelector: @selector(addObject:)];

  while ((path = (*nxtImp)(direnum, @selector(nextObject))) != nil)
    {
      (*addImp)(content, @selector(addObject:), path);
    }

  RELEASE(direnum);

  return [content makeImmutableCopyOnFail: NO];
}

/**
 * Creates a symbolic link at path which links to the location
 * specified by otherPath.
 */
- (BOOL) createSymbolicLinkAtPath: (NSString*)path
		      pathContent: (NSString*)otherPath
{
#ifdef HAVE_SYMLINK
  const char* newpath = [self fileSystemRepresentationWithPath: path];
  const char* oldpath = [self fileSystemRepresentationWithPath: otherPath];

  return (symlink(oldpath, newpath) == 0);
#else
  return NO;
#endif
}

/**
 * Returns the name of the file or directory that the symbolic link
 * at path points to.
 */
- (NSString*) pathContentOfSymbolicLinkAtPath: (NSString*)path
{
#ifdef HAVE_READLINK
  char  buf[PATH_MAX];
  const char* lpath = [self fileSystemRepresentationWithPath: path];
  int   llen = readlink(lpath, buf, PATH_MAX-1);

  if (llen > 0)
    {
      return [self stringWithFileSystemRepresentation: buf length: llen];
    }
  else
    {
      return nil;
    }
#else
  return nil;
#endif
}

#if	defined(__MINGW__)
- (const GSNativeChar*) fileSystemRepresentationWithPath: (NSString*)path
{
  if (path != nil && [path rangeOfString: @"/"].length > 0)
    {
      path = [path stringByReplacingString: @"/" withString: @"\\"];
    }
  return
    (const GSNativeChar*)[path cStringUsingEncoding: NSUnicodeStringEncoding];
}
- (NSString*) stringWithFileSystemRepresentation: (const GSNativeChar*)string
					  length: (NSUInteger)len
{
  return [NSString stringWithCharacters: string length: len];
}
#else
- (const GSNativeChar*) fileSystemRepresentationWithPath: (NSString*)path
{
  return
    (const GSNativeChar*)[path cStringUsingEncoding: defaultEncoding];
}
- (NSString*) stringWithFileSystemRepresentation: (const GSNativeChar*)string
					  length: (NSUInteger)len
{
  return AUTORELEASE([[NSString allocWithZone: NSDefaultMallocZone()]
    initWithBytes: string length: len encoding: defaultEncoding]);
}
#endif

@end /* NSFileManager */

/* A directory to enumerate.  We keep a stack of the directories we
   still have to enumerate.  We start by putting the top-level
   directory into the stack, then we start reading files from it
   (using readdir).  If we find a file which is actually a directory,
   and if we have to recurse into it, we create a new
   GSEnumeratedDirectory struct for the subdirectory, open its DIR
   *pointer for reading, and put it on top of the stack, so next time
   -nextObject is called, it will read from that directory instead of
   the top level one.  Once all the subdirectory is read, it is
   removed from the stack, so the top of the stack if the top
   directory again, and enumeration continues in there.  */
typedef	struct	_GSEnumeratedDirectory {
  NSString *path;
  _DIR *pointer;
} GSEnumeratedDirectory;


static inline void gsedRelease(GSEnumeratedDirectory X)
{
  DESTROY(X.path);
  _CLOSEDIR(X.pointer);
}

#define GSI_ARRAY_TYPES	0
#define GSI_ARRAY_TYPE	GSEnumeratedDirectory
#define GSI_ARRAY_RELEASE(A, X)   gsedRelease(X.ext)
#define GSI_ARRAY_RETAIN(A, X)

#include "GNUstepBase/GSIArray.h"


@implementation NSDirectoryEnumerator
/*
 * The Objective-C interface hides a traditional C implementation.
 * This was the only way I could get near the speed of standard unix
 * tools for big directories.
 */

+ (void) initialize
{
  if (self == [NSDirectoryEnumerator class])
    {
    }
}

/**
 *  Initialize instance to enumerate contents at path, which should be a
 *  directory and can be specified in relative or absolute, and may include
 *  Unix conventions like '<code>~</code>' for user home directory, which will
 *  be appropriately converted on Windoze systems.  The justContents flag, if
 *  set, is equivalent to recurseIntoSubdirectories = NO and followSymlinks =
 *  NO, but the implementation will be made more efficient.
 */
- (id) initWithDirectoryPath: (NSString*)path
   recurseIntoSubdirectories: (BOOL)recurse
	      followSymlinks: (BOOL)follow
		justContents: (BOOL)justContents
			 for: (NSFileManager*)mgr
{
//TODO: the justContents flag is currently basically useless and should be
//      removed
  _DIR		*dir_pointer;
  const _CHAR	*localPath;

  self = [super init];

  _mgr = RETAIN(mgr);
#if	GS_WITH_GC
  _stack = NSAllocateCollectable(sizeof(GSIArray_t), NSScannedOption);
#else
  _stack = NSZoneMalloc([self zone], sizeof(GSIArray_t));
#endif
  GSIArrayInitWithZoneAndCapacity(_stack, [self zone], 64);

  _flags.isRecursive = recurse;
  _flags.isFollowing = follow;
  _flags.justContents = justContents;

  _topPath = [[NSString alloc] initWithString: path];

  localPath = [_mgr fileSystemRepresentationWithPath: path];
  dir_pointer = _OPENDIR(localPath);
  if (dir_pointer)
    {
      GSIArrayItem item;

      item.ext.path = @"";
      item.ext.pointer = dir_pointer;

      GSIArrayAddItem(_stack, item);
    }
  else
    {
      NSLog(@"Failed to recurse into directory '%@' - %@", path,
	[NSError _last]);
    }
  return self;
}

- (void) dealloc
{
  GSIArrayEmpty(_stack);
  NSZoneFree([self zone], _stack);
  DESTROY(_topPath);
  DESTROY(_currentFilePath);
  DESTROY(_mgr);
  [super dealloc];
}

/**
 * Returns a dictionary containing the attributes of the directory
 * at which enumeration started. <br />
 * The contents of this dictionary are as produced by
 * [NSFileManager-fileAttributesAtPath:traverseLink:]
 */
- (NSDictionary*) directoryAttributes
{
  return [_mgr fileAttributesAtPath: _topPath
		       traverseLink: _flags.isFollowing];
}

/**
 * Returns a dictionary containing the attributes of the file
 * currently being enumerated. <br />
 * The contents of this dictionary are as produced by
 * [NSFileManager-fileAttributesAtPath:traverseLink:]
 */
- (NSDictionary*) fileAttributes
{
  return [_mgr fileAttributesAtPath: _currentFilePath
		       traverseLink: _flags.isFollowing];
}

/**
 * Informs the receiver that any descendents of the current directory
 * should be skipped rather than enumerated.  Use this to avoid enumerating
 * the contents of directories you are not interested in.
 */
- (void) skipDescendents
{
  if (GSIArrayCount(_stack) > 0)
    {
      GSIArrayRemoveLastItem(_stack);
      if (_currentFilePath != 0)
	{
	  DESTROY(_currentFilePath);
	}
    }
}

/*
 * finds the next file according to the top enumerator
 * - if there is a next file it is put in currentFile
 * - if the current file is a directory and if isRecursive calls
 * recurseIntoDirectory: currentFile
 * - if the current file is a symlink to a directory and if isRecursive
 * and isFollowing calls recurseIntoDirectory: currentFile
 * - if at end of current directory pops stack and attempts to
 * find the next entry in the parent
 * - sets currentFile to nil if there are no more files to enumerate
 */
- (id) nextObject
{
  NSString *returnFileName = 0;

  if (_currentFilePath != 0)
    {
      DESTROY(_currentFilePath);
    }

  while (GSIArrayCount(_stack) > 0)
    {
      GSEnumeratedDirectory dir = GSIArrayLastItem(_stack).ext;
      struct _DIRENT	*dirbuf;
      struct _STATB	statbuf;

      dirbuf = _READDIR(dir.pointer);

      if (dirbuf)
	{
#if defined(__MINGW__)
	  /* Skip "." and ".." directory entries */
	  if (wcscmp(dirbuf->d_name, L".") == 0
	    || wcscmp(dirbuf->d_name, L"..") == 0)
	    {
	      continue;
	    }
	  /* Name of file to return  */
	  returnFileName = [_mgr
	    stringWithFileSystemRepresentation: dirbuf->d_name
	    length: wcslen(dirbuf->d_name)];
#else
	  /* Skip "." and ".." directory entries */
	  if (strcmp(dirbuf->d_name, ".") == 0
	    || strcmp(dirbuf->d_name, "..") == 0)
	    {
	      continue;
	    }
	  /* Name of file to return  */
	  returnFileName = [_mgr
	    stringWithFileSystemRepresentation: dirbuf->d_name
	    length: strlen(dirbuf->d_name)];
#endif
	  returnFileName = RETAIN([dir.path stringByAppendingPathComponent:
	    returnFileName]);

	  /* TODO - can this one can be removed ? */
	  if (!_flags.justContents)
	    _currentFilePath = RETAIN([_topPath stringByAppendingPathComponent:
	      returnFileName]);

	  if (_flags.isRecursive == YES)
	    {
	      // Do not follow links
#ifdef S_IFLNK
#ifdef __MINGW__
#warning "lstat does not support unichars"
#else
	      if (!_flags.isFollowing)
		{
		  if (lstat([_mgr fileSystemRepresentationWithPath:
		    _currentFilePath], &statbuf) != 0)
		    {
		      break;
		    }
		  // If link then return it as link
		  if (S_IFLNK == (S_IFMT & statbuf.st_mode))
		    {
		      break;
		    }
		}
	      else
#endif
#endif
		{
		  if (_STAT([_mgr fileSystemRepresentationWithPath:
		    _currentFilePath], &statbuf) != 0)
		    {
		      break;
		    }
		}
	      if (S_IFDIR == (S_IFMT & statbuf.st_mode))
		{
		  _DIR*  dir_pointer;

		  dir_pointer
		    = _OPENDIR([_mgr fileSystemRepresentationWithPath:
		    _currentFilePath]);
		  if (dir_pointer)
		    {
		      GSIArrayItem item;

		      item.ext.path = RETAIN(returnFileName);
		      item.ext.pointer = dir_pointer;

		      GSIArrayAddItem(_stack, item);
		    }
		  else
		    {
		      NSLog(@"Failed to recurse into directory '%@' - %@",
			_currentFilePath, [NSError _last]);
		    }
		}
	    }
	  break;	// Got a file name - break out of loop
	}
      else
	{
	  GSIArrayRemoveLastItem(_stack);
	  if (_currentFilePath != 0)
	    {
	      DESTROY(_currentFilePath);
	    }
	}
    }
  return AUTORELEASE(returnFileName);
}

@end /* NSDirectoryEnumerator */

/**
 * Convenience methods for accessing named file attributes in a dictionary.
 */
@implementation NSDictionary(NSFileAttributes)

/**
 * Return the file creation date attribute (or nil if not found).
 */
- (NSDate*) fileCreationDate
{
  return [self objectForKey: NSFileCreationDate];
}

/**
 * Return the file extension hidden attribute (or NO if not found).
 */
- (BOOL) fileExtensionHidden
{
  return [[self objectForKey: NSFileExtensionHidden] boolValue];
}

/**
 *  Returns HFS creator attribute (OS X).
 */
- (OSType) fileHFSCreatorCode
{
  return [[self objectForKey: NSFileHFSCreatorCode] unsignedLongValue];
}

/**
 *  Returns HFS type code attribute (OS X).
 */
- (OSType) fileHFSTypeCode
{
  return [[self objectForKey: NSFileHFSTypeCode] unsignedLongValue];
}

/**
 * Return the file append only attribute (or NO if not found).
 */
- (BOOL) fileIsAppendOnly
{
  return [[self objectForKey: NSFileAppendOnly] boolValue];
}

/**
 * Return the file immutable attribute (or NO if not found).
 */
- (BOOL) fileIsImmutable
{
  return [[self objectForKey: NSFileImmutable] boolValue];
}

/**
 * Return the size of the file, or NSNotFound if the file size attribute
 * is not found in the dictionary.
 */
- (unsigned long long) fileSize
{
  NSNumber	*n = [self objectForKey: NSFileSize];

  if (n == nil)
    {
      return NSNotFound;
    }
  return [n unsignedLongLongValue];
}

/**
 * Return the file type attribute or nil if not present.
 */
- (NSString*) fileType
{
  return [self objectForKey: NSFileType];
}

/**
 * Return the file owner account name attribute or nil if not present.
 */
- (NSString*) fileOwnerAccountName
{
  return [self objectForKey: NSFileOwnerAccountName];
}

/**
 * Return an NSNumber with the numeric value of the NSFileOwnerAccountID attribute
 * in the dictionary, or nil if the attribute is not present.
 */
- (NSNumber*) fileOwnerAccountID
{
  return [self objectForKey: NSFileOwnerAccountID];
}

/**
 * Return the file group owner account name attribute or nil if not present.
 */
- (NSString*) fileGroupOwnerAccountName
{
  return [self objectForKey: NSFileGroupOwnerAccountName];
}

/**
 * Return an NSNumber with the numeric value of the NSFileGroupOwnerAccountID attribute
 * in the dictionary, or nil if the attribute is not present.
 */
- (NSNumber*) fileGroupOwnerAccountID
{
  return [self objectForKey: NSFileGroupOwnerAccountID];
}

/**
 * Return the file modification date attribute (or nil if not found)
 */
- (NSDate*) fileModificationDate
{
  return [self objectForKey: NSFileModificationDate];
}

/**
 * Return the file posix permissions attribute (or NSNotFound if
 * the attribute is not present in the dictionary).
 */
- (NSUInteger) filePosixPermissions
{
  NSNumber	*n = [self objectForKey: NSFilePosixPermissions];

  if (n == nil)
    {
      return NSNotFound;
    }
  return [n unsignedIntegerValue];
}

/**
 * Return the file system number attribute (or NSNotFound if
 * the attribute is not present in the dictionary).
 */
- (NSUInteger) fileSystemNumber
{
  NSNumber	*n = [self objectForKey: NSFileSystemNumber];

  if (n == nil)
    {
      return NSNotFound;
    }
  return [n unsignedIntegerValue];
}

/**
 * Return the file system file identification number attribute
 * or NSNotFound if the attribute is not present in the dictionary).
 */
- (NSUInteger) fileSystemFileNumber
{
  NSNumber	*n = [self objectForKey: NSFileSystemFileNumber];

  if (n == nil)
    {
      return NSNotFound;
    }
  return [n unsignedIntegerValue];
}
@end

@implementation NSFileManager (PrivateMethods)

- (BOOL) _copyFile: (NSString*)source
	    toFile: (NSString*)destination
	   handler: (id)handler
{
#if defined(__MINGW__)
  if (CopyFileW([self fileSystemRepresentationWithPath: source],
    [self fileSystemRepresentationWithPath: destination], NO))
    {
      return YES;
    }

  return [self _proceedAccordingToHandler: handler
				 forError: @"cannot copy file"
				   inPath: source
				 fromPath: source
				   toPath: destination];

#else
  NSDictionary	*attributes;
  unsigned long long	fileSize;
  unsigned long long	i;
  int		bufsize = 8096;
  int		sourceFd;
  int		destFd;
  int		fileMode;
  int		rbytes;
  int		wbytes;
  char		buffer[bufsize];

  /* Assumes source is a file and exists! */
  NSAssert1 ([self fileExistsAtPath: source],
    @"source file '%@' does not exist!", source);

  attributes = [self fileAttributesAtPath: source traverseLink: NO];
  NSAssert1 (attributes, @"could not get the attributes for file '%@'",
    source);

  fileSize = [attributes fileSize];
  fileMode = [attributes filePosixPermissions];

  /* Open the source file. In case of error call the handler. */
  sourceFd = open([self fileSystemRepresentationWithPath: source],
    GSBINIO|O_RDONLY);
  if (sourceFd < 0)
    {
      return [self _proceedAccordingToHandler: handler
				     forError: @"cannot open file for reading"
				       inPath: source
				     fromPath: source
				       toPath: destination];
    }

  /* Open the destination file. In case of error call the handler. */
  destFd = open([self fileSystemRepresentationWithPath: destination],
    GSBINIO|O_WRONLY|O_CREAT|O_TRUNC, fileMode);
  if (destFd < 0)
    {
      close (sourceFd);

      return [self _proceedAccordingToHandler: handler
				     forError:  @"cannot open file for writing"
				       inPath: destination
				     fromPath: source
				       toPath: destination];
    }

  /* Read bufsize bytes from source file and write them into the destination
     file. In case of errors call the handler and abort the operation. */
  for (i = 0; i < fileSize; i += rbytes)
    {
      rbytes = read (sourceFd, buffer, bufsize);
      if (rbytes < 0)
	{
          close (sourceFd);
          close (destFd);

          return [self _proceedAccordingToHandler: handler
					 forError: @"cannot read from file"
					   inPath: source
					 fromPath: source
					   toPath: destination];
	}

      wbytes = write (destFd, buffer, rbytes);
      if (wbytes != rbytes)
	{
          close (sourceFd);
          close (destFd);

          return [self _proceedAccordingToHandler: handler
					 forError: @"cannot write to file"
					   inPath: destination
					 fromPath: source
					   toPath: destination];
        }
    }
  close (sourceFd);
  close (destFd);

  return YES;
#endif
}

- (BOOL) _copyPath: (NSString*)source
	    toPath: (NSString*)destination
	   handler: handler
{
  NSDirectoryEnumerator	*enumerator;
  NSString		*dirEntry;
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];

  enumerator = [self enumeratorAtPath: source];
  while ((dirEntry = [enumerator nextObject]))
    {
      NSString		*sourceFile;
      NSString		*fileType;
      NSString		*destinationFile;
      NSDictionary	*attributes;

      attributes = [enumerator fileAttributes];
      fileType = [attributes fileType];
      sourceFile = [source stringByAppendingPathComponent: dirEntry];
      destinationFile
	= [destination stringByAppendingPathComponent: dirEntry];

      [self _sendToHandler: handler willProcessPath: sourceFile];

      if ([fileType isEqual: NSFileTypeDirectory])
	{
	  BOOL	dirOK;

	  dirOK = [self createDirectoryAtPath: destinationFile
				   attributes: attributes];
	  if (dirOK == NO)
	    {
              if (![self _proceedAccordingToHandler: handler
					   forError: _lastError
					     inPath: destinationFile
					   fromPath: sourceFile
					     toPath: destinationFile])
                {
                  return NO;
                }
	      /*
	       * We may have managed to create the directory but not set
	       * its attributes ... if so we can continue copying.
	       */
	      if (![self fileExistsAtPath: destinationFile isDirectory: &dirOK])
	        {
		  dirOK = NO;
	        }
	    }
	  if (dirOK == YES)
	    {
	      [enumerator skipDescendents];
	      if (![self _copyPath: sourceFile
                         toPath: destinationFile
                         handler: handler])
		return NO;
	    }
	}
      else if ([fileType isEqual: NSFileTypeRegular])
	{
	  if (![self _copyFile: sourceFile
			toFile: destinationFile
		       handler: handler])
	    return NO;
	}
      else if ([fileType isEqual: NSFileTypeSymbolicLink])
	{
	  NSString	*path;

	  path = [self pathContentOfSymbolicLinkAtPath: sourceFile];
	  if (![self createSymbolicLinkAtPath: destinationFile
				  pathContent: path])
	    {
              if (![self _proceedAccordingToHandler: handler
		forError: @"cannot create symbolic link"
		inPath: sourceFile
		fromPath: sourceFile
		toPath: destinationFile])
                {
                  return NO;
                }
	    }
	}
      else
	{
	  NSString	*s;

	  s = [NSString stringWithFormat: @"cannot copy file type '%@'",
	    fileType];
	  ASSIGN(_lastError, s);
	  NSLog(@"%@: %@", sourceFile, s);
	  continue;
	}
      [self changeFileAttributes: attributes atPath: destinationFile];
    }
  [pool drain];

  return YES;
}

- (BOOL) _linkPath: (NSString*)source
	    toPath: (NSString*)destination
	   handler: handler
{
#ifdef HAVE_LINK
  NSDirectoryEnumerator	*enumerator;
  NSString		*dirEntry;
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];

  enumerator = [self enumeratorAtPath: source];
  while ((dirEntry = [enumerator nextObject]))
    {
      NSString		*sourceFile;
      NSString		*fileType;
      NSString		*destinationFile;
      NSDictionary	*attributes;

      attributes = [enumerator fileAttributes];
      fileType = [attributes fileType];
      sourceFile = [source stringByAppendingPathComponent: dirEntry];
      destinationFile
	= [destination stringByAppendingPathComponent: dirEntry];

      [self _sendToHandler: handler willProcessPath: sourceFile];

      if ([fileType isEqual: NSFileTypeDirectory] == YES)
	{
	  if ([self createDirectoryAtPath: destinationFile
			       attributes: attributes] == NO)
	    {
              if ([self _proceedAccordingToHandler: handler
					  forError: _lastError
					    inPath: destinationFile
					  fromPath: sourceFile
					    toPath: destinationFile] == NO)
                {
                  return NO;
                }
	    }
	  else
	    {
	      [enumerator skipDescendents];
	      if ([self _linkPath: sourceFile
			   toPath: destinationFile
			  handler: handler] == NO)
		{
		  return NO;
		}
	    }
	}
      else if ([fileType isEqual: NSFileTypeSymbolicLink])
	{
	  NSString	*path;

	  path = [self pathContentOfSymbolicLinkAtPath: sourceFile];
	  if ([self createSymbolicLinkAtPath: destinationFile
				 pathContent: path] == NO)
	    {
              if ([self _proceedAccordingToHandler: handler
		forError: @"cannot create symbolic link"
		inPath: sourceFile
		fromPath: sourceFile
		toPath: destinationFile] == NO)
                {
                  return NO;
                }
	    }
	}
      else
	{
	  if (link([self fileSystemRepresentationWithPath: sourceFile],
	    [self fileSystemRepresentationWithPath: destinationFile]) < 0)
	    {
              if ([self _proceedAccordingToHandler: handler
		forError: @"cannot create hard link"
		inPath: sourceFile
		fromPath: sourceFile
		toPath: destinationFile] == NO)
                {
                  return NO;
                }
	    }
	}
      [self changeFileAttributes: attributes atPath: destinationFile];
    }
  [pool drain];
  return YES;
#else
  return NO;
#endif
}

- (void) _sendToHandler: (id) handler
        willProcessPath: (NSString*) path
{
  if ([handler respondsToSelector: @selector (fileManager:willProcessPath:)])
    {
      [handler fileManager: self willProcessPath: path];
    }
}

- (BOOL) _proceedAccordingToHandler: (id) handler
                           forError: (NSString*) error
                             inPath: (NSString*) path
{
  if ([handler respondsToSelector:
    @selector (fileManager:shouldProceedAfterError:)])
    {
      NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                path, @"Path",
                                              error, @"Error", nil];
      return [handler fileManager: self
	  shouldProceedAfterError: errorInfo];
    }
  return NO;
}

- (BOOL) _proceedAccordingToHandler: (id) handler
                           forError: (NSString*) error
                             inPath: (NSString*) path
                           fromPath: (NSString*) fromPath
                             toPath: (NSString*) toPath
{
  if ([handler respondsToSelector:
    @selector (fileManager:shouldProceedAfterError:)])
    {
      NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                path, @"Path",
                                              fromPath, @"FromPath",
                                              toPath, @"ToPath",
                                              error, @"Error", nil];
      return [handler fileManager: self
	  shouldProceedAfterError: errorInfo];
    }
  return NO;
}

@end /* NSFileManager (PrivateMethods) */



@implementation	GSAttrDictionary

static NSSet	*fileKeys = nil;

+ (NSDictionary*) attributesAt: (const _CHAR*)lpath
		  traverseLink: (BOOL)traverse
{
  GSAttrDictionary	*d;
  unsigned		l = 0;
  unsigned		i;

  if (lpath == 0 || *lpath == 0)
    {
      return nil;
    }
  while (lpath[l] != 0)
    {
      l++;
    }
  d = (GSAttrDictionary*)NSAllocateObject(self, (l+1)*sizeof(_CHAR),
    NSDefaultMallocZone());

#if defined(S_IFLNK) && !defined(__MINGW__)
  if (traverse == NO)
    {
      if (lstat(lpath, &d->statbuf) != 0)
	{
	  DESTROY(d);
	}
    }
  else
#endif
  if (_STAT(lpath, &d->statbuf) != 0)
    {
      DESTROY(d);
    }
  if (d != nil)
    {
      for (i = 0; i <= l; i++)
	{
	  d->_path[i] = lpath[i];
	}
    }
  return AUTORELEASE(d);
}

+ (void) initialize
{
  if (fileKeys == nil)
    {
      fileKeys = [NSSet setWithObjects:
	NSFileAppendOnly,
	NSFileCreationDate,
	NSFileDeviceIdentifier,
	NSFileExtensionHidden,
	NSFileGroupOwnerAccountName,
	NSFileGroupOwnerAccountID,
	NSFileHFSCreatorCode,
	NSFileHFSTypeCode,
	NSFileImmutable,
	NSFileModificationDate,
	NSFileOwnerAccountName,
	NSFileOwnerAccountID,
	NSFilePosixPermissions,
	NSFileReferenceCount,
	NSFileSize,
	NSFileSystemFileNumber,
	NSFileSystemNumber,
	NSFileType,
	nil];
      IF_NO_GC([fileKeys retain];)
    }
}

- (NSUInteger) count
{
  return [fileKeys count];
}

- (NSDate*) fileCreationDate
{
  /*
   * FIXME ... not sure there is any way to get a creation date :-(
   * Use the earlier of ctime or mtime
   */
  if (statbuf.st_ctime < statbuf.st_mtime)
    return [NSDate dateWithTimeIntervalSince1970: statbuf.st_ctime];
  else
    return [NSDate dateWithTimeIntervalSince1970: statbuf.st_mtime];
}

- (BOOL) fileExtensionHidden
{
  return NO;
}

- (NSNumber*) fileGroupOwnerAccountID
{
  return [NSNumber numberWithInt: statbuf.st_gid];
}

- (NSString*) fileGroupOwnerAccountName
{
  NSString	*group = @"UnknownGroup";

#if	defined(__MINGW__)
  DWORD		returnCode = 0;
  PSID		sidOwner;
  BOOL		result = TRUE;
  _CHAR		account[BUFSIZ];
  _CHAR		domain[BUFSIZ];
  DWORD		accountSize = 1024;
  DWORD		domainSize = 1024;
  SID_NAME_USE	eUse = SidTypeUnknown;
  HANDLE	hFile;
  PSECURITY_DESCRIPTOR pSD;

  // Get the handle of the file object.
  hFile = CreateFileW(
    _path,
    GENERIC_READ,
    FILE_SHARE_READ,
    0,
    OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS,
    0);

  // Check GetLastError for CreateFile error code.
  if (hFile == INVALID_HANDLE_VALUE)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      NSDebugMLog(@"Error %d getting file handle for '%S'",
        dwErrorCode, _path);
      return group;
    }

  // Get the group SID of the file.
  returnCode = GetSecurityInfo(
    hFile,
    SE_FILE_OBJECT,
    GROUP_SECURITY_INFORMATION,
    0,
    &sidOwner,
    0,
    0,
    &pSD);

  CloseHandle(hFile);

  // Check GetLastError for GetSecurityInfo error condition.
  if (returnCode != ERROR_SUCCESS)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      NSDebugMLog(@"Error %d getting security info for '%S'",
        dwErrorCode, _path);
      return group;
    }

  // First call to LookupAccountSid to get the buffer sizes.
  result = LookupAccountSidW(
    0,           // local computer
    sidOwner,
    account,
    (LPDWORD)&accountSize,
    domain,
    (LPDWORD)&domainSize,
    &eUse);

  // Check GetLastError for LookupAccountSid error condition.
  if (result == FALSE)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      if (dwErrorCode == ERROR_NONE_MAPPED)
	NSDebugMLog(@"Error %d in LookupAccountSid for '%S'", _path);
      else
        NSDebugMLog(@"Error %d getting security info for '%S'",
          dwErrorCode, _path);
      return group;
    }

  if (accountSize >= 1024)
    {
      NSDebugMLog(@"Account name for '%S' is unreasonably long", _path);
      return group;
    }
  return [NSString stringWithCharacters: account length: accountSize];
#else
#if defined(HAVE_GRP_H)
#if defined(HAVE_GETGRGID_H)
  struct group gp;
  struct group *p;
  char buf[BUFSIZ*10];

  if (getgrgid_r(statbuf.st_gid, &gp, buf, sizeof(buf), &p) == 0)
    {
      group = [NSString stringWithCString: gp.gr_name
				 encoding: defaultEncoding];
    }
#else
#if defined(HAVE_GETGRGID)
  struct group	*gp;

  [gnustep_global_lock lock];
  gp = getgrgid(statbuf.st_gid);
  if (gp != 0)
    {
      group = [NSString stringWithCString: gp->gr_name
				 encoding: defaultEncoding];
    }
  [gnustep_global_lock unlock];
#endif
#endif
#endif
#endif
  return group;
}

- (OSType) fileHFSCreatorCode
{
  return 0;
}

- (OSType) fileHFSTypeCode
{
  return 0;
}

- (BOOL) fileIsAppendOnly
{
  return 0;
}

- (BOOL) fileIsImmutable
{
  return 0;
}

- (NSDate*) fileModificationDate
{
  return [NSDate dateWithTimeIntervalSince1970: statbuf.st_mtime];
}

- (NSUInteger) filePosixPermissions
{
  return (statbuf.st_mode & ~S_IFMT);
}

- (NSNumber*) fileOwnerAccountID
{
  return [NSNumber numberWithInt: statbuf.st_uid];
}

- (NSString*) fileOwnerAccountName
{
  NSString	*owner = @"UnknownUser";

#if	defined(__MINGW__)
  DWORD		returnCode = 0;
  PSID		sidOwner;
  BOOL		result = TRUE;
  _CHAR		account[BUFSIZ];
  _CHAR		domain[BUFSIZ];
  DWORD		accountSize = 1024;
  DWORD		domainSize = 1024;
  SID_NAME_USE	eUse = SidTypeUnknown;
  HANDLE	hFile;
  PSECURITY_DESCRIPTOR pSD;

  // Get the handle of the file object.
  hFile = CreateFileW(
    _path,
    GENERIC_READ,
    FILE_SHARE_READ,
    0,
    OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS,
    0);

  // Check GetLastError for CreateFile error code.
  if (hFile == INVALID_HANDLE_VALUE)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      NSDebugMLog(@"Error %d getting file handle for '%S'",
        dwErrorCode, _path);
      return owner;
    }

  // Get the owner SID of the file.
  returnCode = GetSecurityInfo(
    hFile,
    SE_FILE_OBJECT,
    OWNER_SECURITY_INFORMATION,
    &sidOwner,
    0,
    0,
    0,
    &pSD);

  CloseHandle(hFile);

  // Check GetLastError for GetSecurityInfo error condition.
  if (returnCode != ERROR_SUCCESS)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      NSDebugMLog(@"Error %d getting security info for '%S'",
        dwErrorCode, _path);
      return owner;
    }

  // First call to LookupAccountSid to get the buffer sizes.
  result = LookupAccountSidW(
    0,           // local computer
    sidOwner,
    account,
    (LPDWORD)&accountSize,
    domain,
    (LPDWORD)&domainSize,
    &eUse);

  // Check GetLastError for LookupAccountSid error condition.
  if (result == FALSE)
    {
      DWORD dwErrorCode = 0;

      dwErrorCode = GetLastError();
      if (dwErrorCode == ERROR_NONE_MAPPED)
	NSDebugMLog(@"Error %d in LookupAccountSid for '%S'", _path);
      else
        NSDebugMLog(@"Error %d getting security info for '%S'",
          dwErrorCode, _path);
      return owner;
    }

  if (accountSize >= 1024)
    {
      NSDebugMLog(@"Account name for '%S' is unreasonably long", _path);
      return owner;
    }
  return [NSString stringWithCharacters: account length: accountSize];
#else
#ifdef HAVE_PWD_H
#if     defined(HAVE_GETPWUID_R)
  struct passwd pw;
  struct passwd *p;
  char buf[BUFSIZ*10];

  if (getpwuid_r(statbuf.st_uid, &pw, buf, sizeof(buf), &p) == 0)
    {
      owner = [NSString stringWithCString: pw.pw_name
				 encoding: defaultEncoding];
    }
#else
#if     defined(HAVE_GETPWUID)
  struct passwd *pw;

  [gnustep_global_lock lock];
  pw = getpwuid(statbuf.st_uid);
  if (pw != 0)
    {
      owner = [NSString stringWithCString: pw->pw_name
				 encoding: defaultEncoding];
    }
  [gnustep_global_lock unlock];
#endif
#endif
#endif /* HAVE_PWD_H */
#endif
  return owner;
}

- (unsigned long long) fileSize
{
  return statbuf.st_size;
}

- (NSUInteger) fileSystemFileNumber
{
  return statbuf.st_ino;
}

- (NSUInteger) fileSystemNumber
{
#if defined(__MINGW__)
  DWORD volumeSerialNumber = 0;
  _CHAR volumePathName[128];
  if (GetVolumePathNameW(_path,volumePathName,128))
  {
    GetVolumeInformationW(volumePathName,NULL,0,&volumeSerialNumber,NULL,NULL,NULL,0);
  }

  return (NSUInteger)volumeSerialNumber;
#else
  return statbuf.st_dev;
#endif
}

- (NSString*) fileType
{
  switch (statbuf.st_mode & S_IFMT)
    {
      case S_IFREG: return NSFileTypeRegular;
      case S_IFDIR: return NSFileTypeDirectory;
      case S_IFCHR: return NSFileTypeCharacterSpecial;
      case S_IFBLK: return NSFileTypeBlockSpecial;
#ifdef S_IFLNK
      case S_IFLNK: return NSFileTypeSymbolicLink;
#endif
      case S_IFIFO: return NSFileTypeFifo;
#ifdef S_IFSOCK
      case S_IFSOCK: return NSFileTypeSocket;
#endif
      default: return NSFileTypeUnknown;
    }
}

- (NSEnumerator*) keyEnumerator
{
  return [fileKeys objectEnumerator];
}

- (NSEnumerator*) objectEnumerator
{
  return [GSAttrDictionaryEnumerator enumeratorFor: self];
}

- (id) objectForKey: (id)key
{
  int	count = 0;

  while (key != 0 && count < 2)
    {
      if (key == NSFileAppendOnly)
	return [NSNumber numberWithBool: [self fileIsAppendOnly]];
      if (key == NSFileCreationDate)
	return [self fileCreationDate];
      if (key == NSFileDeviceIdentifier)
	return [NSNumber numberWithUnsignedInt: statbuf.st_dev];
      if (key == NSFileExtensionHidden)
	return [NSNumber numberWithBool: [self fileExtensionHidden]];
      if (key == NSFileGroupOwnerAccountName)
	return [self fileGroupOwnerAccountName];
      if (key == NSFileGroupOwnerAccountID)
	return [self fileGroupOwnerAccountID];
      if (key == NSFileHFSCreatorCode)
	return [NSNumber numberWithUnsignedLong: [self fileHFSCreatorCode]];
      if (key == NSFileHFSTypeCode)
	return [NSNumber numberWithUnsignedLong: [self fileHFSTypeCode]];
      if (key == NSFileImmutable)
	return [NSNumber numberWithBool: [self fileIsImmutable]];
      if (key == NSFileModificationDate)
	return [self fileModificationDate];
      if (key == NSFileOwnerAccountName)
	return [self fileOwnerAccountName];
      if (key == NSFileOwnerAccountID)
	return [self fileOwnerAccountID];
      if (key == NSFilePosixPermissions)
	return [NSNumber numberWithUnsignedInt: [self filePosixPermissions]];
      if (key == NSFileReferenceCount)
	return [NSNumber numberWithUnsignedInt: statbuf.st_nlink];
      if (key == NSFileSize)
	return [NSNumber numberWithUnsignedLongLong: [self fileSize]];
      if (key == NSFileSystemFileNumber)
	return [NSNumber numberWithUnsignedInt: [self fileSystemFileNumber]];
      if (key == NSFileSystemNumber)
	return [NSNumber numberWithUnsignedInt: [self fileSystemNumber]];
      if (key == NSFileType)
	return [self fileType];

      /*
       * Now, if we didn't get an exact pointer match, check for
       * string equalities and ensure we get an exact match next
       * time round the loop.
       */
      count++;
      key = [fileKeys member: key];
    }
  if (count >= 2)
    {
      NSLog(@"Warning ... key '%@' not handled", key);
    }
  return nil;
}

@end	/* GSAttrDictionary */

@implementation	GSAttrDictionaryEnumerator
+ (NSEnumerator*) enumeratorFor: (NSDictionary*)d
{
  GSAttrDictionaryEnumerator	*e;

  e = (GSAttrDictionaryEnumerator*)
    NSAllocateObject(self, 0, NSDefaultMallocZone());
  e->dictionary = RETAIN(d);
  e->enumerator = RETAIN([fileKeys objectEnumerator]);
  return AUTORELEASE(e);
}

- (void) dealloc
{
  RELEASE(enumerator);
  RELEASE(dictionary);
  [super dealloc];
}

- (id) nextObject
{
  NSString	*key = [enumerator nextObject];
  id		val = nil;

  if (key != nil)
    {
      val = [dictionary objectForKey: key];
    }
  return val;
}
@end

NSString * const NSFileAppendOnly = @"NSFileAppendOnly";
NSString * const NSFileCreationDate = @"NSFileCreationDate";
NSString * const NSFileDeviceIdentifier = @"NSFileDeviceIdentifier";
NSString * const NSFileExtensionHidden = @"NSFileExtensionHidden";
NSString * const NSFileGroupOwnerAccountID = @"NSFileGroupOwnerAccountID";
NSString * const NSFileGroupOwnerAccountName = @"NSFileGroupOwnerAccountName";
NSString * const NSFileHFSCreatorCode = @"NSFileHFSCreatorCode";
NSString * const NSFileHFSTypeCode = @"NSFileHFSTypeCode";
NSString * const NSFileImmutable = @"NSFileImmutable";
NSString * const NSFileModificationDate = @"NSFileModificationDate";
NSString * const NSFileOwnerAccountID = @"NSFileOwnerAccountID";
NSString * const NSFileOwnerAccountName = @"NSFileOwnerAccountName";
NSString * const NSFilePosixPermissions = @"NSFilePosixPermissions";
NSString * const NSFileReferenceCount = @"NSFileReferenceCount";
NSString * const NSFileSize = @"NSFileSize";
NSString * const NSFileSystemFileNumber = @"NSFileSystemFileNumber";
NSString * const NSFileSystemFreeNodes = @"NSFileSystemFreeNodes";
NSString * const NSFileSystemFreeSize = @"NSFileSystemFreeSize";
NSString * const NSFileSystemNodes = @"NSFileSystemNodes";
NSString * const NSFileSystemNumber = @"NSFileSystemNumber";
NSString * const NSFileSystemSize = @"NSFileSystemSize";
NSString * const NSFileType = @"NSFileType";
NSString * const NSFileTypeBlockSpecial = @"NSFileTypeBlockSpecial";
NSString * const NSFileTypeCharacterSpecial = @"NSFileTypeCharacterSpecial";
NSString * const NSFileTypeDirectory = @"NSFileTypeDirectory";
NSString * const NSFileTypeFifo = @"NSFileTypeFifo";
NSString * const NSFileTypeRegular = @"NSFileTypeRegular";
NSString * const NSFileTypeSocket = @"NSFileTypeSocket";
NSString * const NSFileTypeSymbolicLink = @"NSFileTypeSymbolicLink";
NSString * const NSFileTypeUnknown = @"NSFileTypeUnknown";



/*
 * Copyright (c) 2013. All rights reserved.
 *
 */



#include <cairo-ft.h>
#include FT_LIST_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_TRUETYPE_TABLES_H
 

/* We just return a (cairo_font_face_t *) as a (CGFontRef) */

static FcPattern *opal_FcPatternCreateFromName(const char *name);

/* We keep an LRU cache of patterns looked up by name to avoid calling
 * fontconfig too frequently (like when refreshing a window repeatedly) */
/* But we cache patterns and let cairo handle FT_Face objects because of
 * memory management problems (lack of reference counting on FT_Face) */
/* We can't use Freetype's Cache Manager to implement our cache because its API
 * seems to be in a flux (for other than Face, CMap, Image and SBit at least) */

/* Number of entries to keep in the cache */
#define CACHE_SIZE  10

static FT_ListRec pattern_cache;

typedef struct cache_entry {
  FT_ListNodeRec node;
  unsigned int hash;
  FcPattern *pat;
} cache_entry;

typedef struct iter_state {
  unsigned int hash;
  FcPattern *pat;
  int cnt;
} iter_state;

static FT_Error cache_iterator(FT_ListNode node, void *user)
{
  cache_entry *entry = (cache_entry *)node;
  iter_state *state = user;

  state->cnt++;
  if (!node) return 1;
  if (entry->hash == state->hash) {
    state->pat = entry->pat;
    FT_List_Up(&pattern_cache, node);
    return 2;
  }
  return 0;
}

static unsigned int hash_string(const char *str)
{
  unsigned int hash;

  for (hash = 0; *str != '\0'; str++)
    hash = 31 * hash + *str;

  return hash;
}

static FcPattern *opal_FcPatternCacheLookup(const char *name)
{
  iter_state state;

  state.cnt = 0;
  state.pat = NULL;
  state.hash = hash_string(name);
  FT_List_Iterate(&pattern_cache, cache_iterator, &state);

  if (state.pat)
    return state.pat;

  state.pat = opal_FcPatternCreateFromName(name);
  if (!state.pat) return NULL;

  if (state.cnt >= CACHE_SIZE) {  /* Remove last entry from the cache */
    FT_ListNode node;

    node = pattern_cache.tail;
    FT_List_Remove(&pattern_cache, node);
    FcPatternDestroy(((cache_entry *)node)->pat);
    free(node);
  }
  /* Add new entry to the cache */
  {
    cache_entry *entry;

    entry = calloc(1, sizeof(*entry));
    if (!entry) {
      NSLog(@"calloc failed");
      return state.pat;
    }
    entry->hash = state.hash;
    entry->pat = state.pat;
    FT_List_Insert(&pattern_cache, (FT_ListNode)entry);
  }
  return state.pat;
}

/* End of cache related things */

static FcPattern *opal_FcPatternCreateFromName(const char *name)
{
  char *family, *traits;
  FcPattern *pat;
  FcResult fcres;
  FcBool success;

  if (!name) return NULL;
  family = strdup(name);
  pat = FcPatternCreate();
  if (!family || !pat) goto error;

  /* Try to parse a Postscript font name and make a corresponding pattern */
  /* Consider everything up to the first dash to be the family name */
  traits = strchr(family, '-');
  if (traits) {
    *traits = '\0';
    traits++;
  }
  success = FcPatternAddString(pat, FC_FAMILY, (FcChar8 *)family);
  if (!success) goto error;
  if (traits) {
    /* FIXME: The following is incomplete and may also be wrong */
    /* Fontconfig assumes Medium Roman Regular so don't care about theese */
    if (strstr(traits, "Bold"))
      success |= FcPatternAddInteger(pat, FC_WEIGHT, FC_WEIGHT_BOLD);
    if (strstr(traits, "Italic"))
      success |= FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_ITALIC);
    if (strstr(traits, "Oblique"))
      success |= FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_OBLIQUE);
    if (strstr(traits, "Condensed"))
      success |= FcPatternAddInteger(pat, FC_WIDTH, FC_WIDTH_CONDENSED);
    if (!success) goto error;
  }

  success = FcConfigSubstitute(NULL, pat, FcMatchPattern);
  if (!success) goto error;
  FcDefaultSubstitute(pat);
  pat = FcFontMatch(NULL, pat, &fcres);
  if (!pat) goto error;
  free(family);
  return pat;

error:
  NSLog(@"opal_FcPatternCreateFromName failed");
  if (family) free (family);
  if (pat) FcPatternDestroy(pat);
  return NULL;
}
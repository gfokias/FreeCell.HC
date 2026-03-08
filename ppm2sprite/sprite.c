#include "sprite.h"

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SPT_BITMAP 23

typedef struct __attribute__((__packed__)) DocBin {
  uint32_t number;
  uint32_t flags;
  uint32_t size;
  uint32_t use_count;
} DocBin;

typedef struct __attribute__((__packed__)) Header {
  uint8_t type;
  int32_t x1;
  int32_t y1;
  int32_t width;
  int32_t height;
} Header;

uint8_t palette(uint8_t r, uint8_t g, uint8_t b)
{ /* default templeos palette, returns 0-15 normally, -1 = transparent on invalid color */
  union {
    uint32_t i32;
    uint8_t i8[4];
  } n;

  n.i8[3] = 0;
  n.i8[2] = r;
  n.i8[1] = g;
  n.i8[0] = b;

  switch (n.i32) {
  case 0x000000: return 0;
  case 0x0000aa: return 1;
  case 0x00aa00: return 2;
  case 0x00aaaa: return 3;
  case 0xaa0000: return 4;
  case 0xaa00aa: return 5;
  case 0xaa5500: return 6;
  case 0xaaaaaa: return 7;
  case 0x555555: return 8;
  case 0x5555ff: return 9;
  case 0x55ff55: return 10;
  case 0x55ffff: return 11;
  case 0xff5555: return 12;
  case 0xff55ff: return 13;
  case 0xffff55: return 14;
  case 0xffffff: return 15;
  }
  return 0xFF; /* transparent */
}

int sprite_from_ppm(FILE* f, const PPM* ppm, uint32_t number)
{ /* bitmap structure: U8 type, I32 x1, I32 y1, I32 width, I32 height, U8 data[], U8 end = \0 */
  const Pixel *p;
  DocBin bin;
  Header header;
  
  uint8_t v;
  int i, j;
  
  bin.number = number;
  bin.flags = 0;
  bin.size = sizeof(header) + sizeof(uint8_t) * (1 + ppm->width * ppm->height);
  bin.use_count = 1;

  if (fwrite(&bin, sizeof(bin), 1, f) != 1) {
    return -1;
  }

  header.type = SPT_BITMAP;
  header.x1 = 0;
  header.y1 = 0;
  header.width = ppm->width;
  header.height = ppm->height;

  if (fwrite(&header, sizeof(header), 1, f) != 1) {
    return -1;
  }

  p = &ppm->data[0];

  for (i = 0; i < ppm->width; i++) {
    for (j = 0; j < ppm->height; j++) {
      v = palette(p->r, p->g, p->b);

      if (fputc(v, f) == EOF) {
	return -1;
      }
      
      p++;
    }
  }

  if (fputc('\0', f) == EOF) {
    return -1;
  }
  
  return 0;
}

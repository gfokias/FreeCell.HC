#ifndef PPM_H_
#define PPM_H_

#include <stdint.h>

typedef struct Pixel
{
  uint8_t r, g, b;
} Pixel;

typedef struct PPM
{
  int width, height;
  Pixel data[0];
} PPM;

/* must be freed by the user */ 
PPM* ppm_read(const char* file);

#endif /* PPM_H_ */

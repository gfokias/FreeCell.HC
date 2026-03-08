#include "ppm.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

int ppm_int(FILE* f)
{ /* returns -1 on failure, skips comments, moves file pointer beyond space */
  static char buffer[128];

  char c;
  long unsigned int i;
  
  for (i = 0; i < sizeof(buffer) - 1; i++) {
    c = fgetc(f);
    
    if (isspace(c) || c == EOF) {
      break;
    } else if (c == '#') {
      while (!(c == '\n' || c == EOF)) {
	c = fgetc(f);
      }
    } else if (!isdigit(c)) {
      return -1;
    }

    buffer[i] = c;
  }

  buffer[i] = '\0';

  return atoi(buffer);
}

PPM* ppm_read(const char* file)
{ /* returns NULL on failure, format: netpbm.sourceforge.net/doc/ppm.html */
  FILE* f;
  Pixel* p; 
  PPM* ppm; 
  int x, y, width, height, maxval, val;

  f = fopen(file, "r");
  
  if (f == NULL) {
    return NULL;
  }

  if (!(fgetc(f) == 'P' && fgetc(f) == '3' && isspace(fgetc(f)))) {
    fclose(f);
    return NULL;
  }

  width = ppm_int(f);

  if (width == -1) {
    fclose(f);
    return NULL;
  }
  
  height = ppm_int(f);

  if (height == -1) {
    fclose(f);
    return NULL;
  }

  maxval = ppm_int(f);

  if (maxval == -1 || maxval > 65535) {
    fclose(f);
    return NULL;
  }

  ppm = malloc(sizeof(*ppm) + sizeof(*ppm->data) * width * height);

  if (ppm == NULL) {
    fclose(f);
    return NULL;
  }

  ppm->width = width;
  ppm->height = height;

  p = &ppm->data[0];

  for (y = 0; y < ppm->height; y++) {
    for (x = 0; x < ppm->width; x++) {
      val = ppm_int(f);

      if (val > maxval) {
	fclose(f);
	free(ppm);
	return NULL;
      }

      p->r = (0xFF * val)/maxval;
      
      val = ppm_int(f);

      if (val > maxval) {
	fclose(f);
	free(ppm);
	return NULL;
      }

      p->g = (0xFF * val)/maxval;
      
      val = ppm_int(f);

      if (val > maxval) {
	fclose(f);
	free(ppm);
	return NULL;
      }

      p->b = (0xFF * val)/maxval;

      p++;
    }
  }

  fclose(f);

  return ppm;
}

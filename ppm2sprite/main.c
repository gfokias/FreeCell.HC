#include "sprite.h"
#include "ppm.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
  FILE* in;
  FILE* out;
  char c;
  int i;
  
  if (argc <= 3) {
    fprintf(stderr,
	    "Usage: %s [in file] [out file] [ppm images]\n\n"
	    "Injects .ppm ASCII images as TempleOS sprite binary data.\n"
	    "Existing binary data is stripped from [in file].\n\n"
	    "If [in file] is -, data will be read from stdin.\n"
	    "If [out file] is -, the result will be written to stdout.\n",
	    argv[0]);
    return 0;
  }

  if (!strcmp(argv[2], "-")) {
    out = stdout;
  } else {
    out = fopen(argv[2], "w");

    if (out == NULL) {
      fprintf(stderr, "Could not open %s: %s\n", argv[2], strerror(errno));
      return 1;
    }
  }

  if (!strcmp(argv[1], "-")) {
    in = stdin;
  } else {
    in = fopen(argv[1], "r");

    if (in == NULL) {
      fprintf(stderr, "Could not open %s: %s\n", argv[1], strerror(errno));
      return 1;
    }
  }

  for (;;) {
    c = fgetc(in);

    if (c == '\0' || c == EOF) {
      break;
    }
    
    fputc(c, out);
  }
  
  fclose(in);
  fputc('\0', out);
  
  for (i = 3; i < argc; i++) {
    PPM* ppm = ppm_read(argv[i]);

    if (ppm == NULL) {
      fprintf(stderr, "Could not open or parse .ppm file %s\n", argv[i]);
      continue;
    }

    if (sprite_from_ppm(out, ppm, i - 2) == -1) {
      fprintf(stderr, "Could not write %s to file\n", argv[1]);
      return 1;
    }
  }
  
  if (out != stdout) {
    fclose(out);
  }

  return 0;
}

#ifndef SPRITE_H_
#define SPRITE_H_

#include "ppm.h"
#include <stdio.h>
#include <stdint.h>

/* writes ppm as bitmap to fd, returns 0 on success, -1 on failure  */ 
int sprite_from_ppm(FILE* f, const PPM* ppm, uint32_t number);

#endif /* SPRITE_H_ */

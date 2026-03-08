TARGET=FreeCell.Out.HC
SOURCE=FreeCell.HC
SPRITES=Club.ppm Diamond.ppm Heart.ppm Spade.ppm # Order should be the same as in FreeCell.HC
PPM2SPRITE=ppm2sprite/ppm2sprite

${TARGET}: ${PPM2SPRITE} ${SOURCE} ${SPRITES}
	${PPM2SPRITE} ${SOURCE} ${TARGET} ${SPRITES}

${PPM2SPRITE}: $(dir ${PPM2SPRITE})
	make -C $<

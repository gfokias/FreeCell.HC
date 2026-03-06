#define SUIT_CLUB 0
#define SUIT_DIAMOND 1
#define SUIT_HEART 2
#define SUIT_SPADE 3
#define NUM_SUITS 4

#define FACE_A 0
#define FACE_2 1
#define FACE_3 2
#define FACE_4 3
#define FACE_5 4
#define FACE_6 5
#define FACE_7 6
#define FACE_8 7
#define FACE_9 8
#define FACE_10 9
#define FACE_K 10
#define FACE_Q 11
#define FACE_J 12
#define NUM_FACES 13

#define DECK_SIZE NUM_SUITS * NUM_FACES

#define NUM_CASCADES 8
#define CASCADE_LENGTH 7

#define SHUFFLES 4
#define GCDS 5

#define CARD_WIDTH 48
#define CARD_HEIGHT 64
#define PADDING 32
#define PADDING_X CARD_WIDTH + 64
#define PADDING_Y CARD_HEIGHT/2

U8 card_faces[DECK_SIZE];
U8 card_suits[DECK_SIZE];

/* Contains card index */
I64 piles[NUM_CASCADES][CASCADE_LENGTH];

static U8 SUIT_CHAR[NUM_SUITS] = "CDHS";
static U8 FACE_CHAR[NUM_FACES] = "A23456789XKQJ";

U8 *SemiRandomOrderU8(U64 n, U8 times = 1, U8 *order = NULL)
{ /* n should be prime or 4. If gcd(I, n) == 1 then {K*I % n, K = 0,1,...} == {1,2,...,n} */
  U64 i, j;
  U8 step;

  if (order == NULL) {
    order = MAlloc(n);
    if (order == NULL) return NULL;
  }

  for (i = 0; i < times * n; i += n) {
    order[i] = Rand % n;
    step = Rand % (n - 1) + 1;
    
    /* Only works because n can only be 4 or 13. 13 is prime. 2 + 1 = 3 % 2 = 1 */
    if (step != 1) {
      if (n % step == 0) step++;
      if (n % step == 0) throw('BadNum');
    }
    
    for (j = 1; i < n * times; i++) {
      order[i + j] = (order[i + j - 1] + step) % n;
    }

    for (j = 0; i < SHUFFLES; i++) {
      SwapU8(&order[i + Rand % n], &order[i + Rand % n]);
    }
  }

  return order;
}

U0 Init()
{
  U64 i, j, card;
  
  SemiRandomOrderU8(NUM_SUITS, DECK_SIZE/NUM_SUITS, card_suits);
  SemiRandomOrderU8(NUM_FACES, DECK_SIZE/NUM_FACES, card_faces); 

  card = 0;
  
  for (i = 0; i < NUM_CASCADES/2; i++) {
    for (j = 0; j < CASCADE_LENGTH - 1; j++) {
      piles[i][j] = card++;
    }
    piles[i][CASCADE_LENGTH - 1] = -1;
  }

  for (i = NUM_CASCADES/2; i < NUM_CASCADES; i++) {
    for (j = 0; j < CASCADE_LENGTH; j++) {
      piles[i][j] = card++;
    }
  }
}

U0 DrawBackground(CDC *dc)
{
  static U64 x, y, i, j, max;

  j = 0;
  max = dc->width_internal * dc->height;

  for (i = 0; i <= max; i++) {
    if (i % dc->width_internal == 0) {
      j = (j + 1) % 2;
    }

    if (i % 2 == j) {
      dc->body[i] = GREEN;
    } else {
      dc->body[i] = DKGRAY;
    }
  }
}

U0 DrawCards(CDC *dc)
{
  U8 buffer[3];
  U64 i, j, x, y, card;

  buffer[sizeof(buffer) - 1] = 0;
  
  for (i = 0; i < NUM_CASCADES; i++) {
    x = PADDING + PADDING_X * i;
    y = PADDING - PADDING_Y;
    
    for (j = 0; j < CASCADE_LENGTH; j++) { 
      card = piles[i][j];

      if (card != -1) {
	y += PADDING_Y;
	
	/* Card outline */
	dc->color = BLACK;
	GrLine(dc, x, y, x, y + CARD_HEIGHT);
	GrLine(dc, x, y, x + CARD_WIDTH, y); 
	GrLine(dc, x + CARD_WIDTH, y, x + CARD_WIDTH, y + CARD_HEIGHT);

	dc->color = WHITE;
	GrRect(dc, x + 1, y + 1, CARD_WIDTH - 1, CARD_HEIGHT - 1);
	
	switch (card_suits[card]) {
	case SUIT_CLUB:
	case SUIT_SPADE:
	  dc->color = BLACK; break;
	case SUIT_HEART:
	case SUIT_DIAMOND:
	  dc->color = RED; break;
	}

	buffer[0] = SUIT_CHAR[card_suits[card]];
	buffer[1] = FACE_CHAR[card_faces[card]];

	GrTextBox3(dc, x + 2, y + 2, 0, buffer);
      }
    }
    
    dc->color = BLACK;
    GrLine(dc, x, y + CARD_HEIGHT, x + CARD_WIDTH, y + CARD_HEIGHT); 
  }
}

U0 DrawIt(CTask *task, CDC *dc)
{
  DrawBackground(dc);
  DrawCards(dc);
}

Bool Loop()
{
  I64 ch;

  while (TRUE) {
    GetKey(&ch);

    switch (ch.u8[0]) {
    case SC_ESC:
      return;
    }

  }
  
}

U0 Klondike()
{
  SettingsPush;

  AutoComplete;
  DocClear;
  DocCursor;
  WinBorder;
  WinMax;
  
  Fs->draw_it = &DrawIt;

  Init;
  Loop;
  
  SettingsPop;
}

Klondike;

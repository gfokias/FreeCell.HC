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
  static U64 i, max;

  DCFill(dc, GREEN);
  
  max = dc->width_internal * dc->height;

  for (i = 0; i < max; i += 2) {
    dc->body[i] = DKGRAY;
  }
}

U8 *CardText(U64 card)
{ /* Single-thread only */
  static U8 buffer[3];

  buffer[0] = SUIT_CHAR[card_suits[card]];
  buffer[1] = FACE_CHAR[card_faces[card]];
  buffer[2] = 0;
  
  return buffer;
}

U0 DrawCards(CDC *dc)
{
  U64 i, j, card;

  for (i = 0; i < NUM_CASCADES; i++) {
    for (j = 0; j < CASCADE_LENGTH; j++) {
      card = piles[i][j];

      if (card != -1) {
	GrTextBox3(dc, i * 32, j * 32, 0, CardText(card));	
      }
    }
  }
}

U0 DrawIt(CTask *task, CDC *dc)
{
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

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
#define CASCADE_LENGTH_A 6
#define CASCADE_LENGTH_B 7

#define SHUFFLES 4
#define GCDS 5

class Card
{
  U8 suit;
  U8 face;
};

Card piles[][PILE_LENGTH];

U8 *RandomOrderU8(U64 n, U8 times = 1, U8 *order = NULL)
{ /* n should be prime or 2. If gcd(I, n) == 1 then {K*I % n, K = 0,1,...} == {1,2,...,n} */
  U64 i;
  U8 step;

  if (order == NULL) {
    order = MAlloc(n);
    if (order == NULL) return NULL;
  }

  order[0] = Rand % n;
  step = Rand % n;
  /* Only works because n can only be 2 or 13. 13 is prime. 2 + 1 = 3 % 2 = 1 */
  if (n % step == 0) step++;
  
  for (i = 1; i < n * times; i++) {
    order[i] = (order[i - 1] + step) % n;
  }

  for (i = 0; i < SHUFFLES * times; i++) {
    SwapU8(&order[Rand % n], &order[Rand % n]);
  }

  return order;
}

U0 Init()
{
  U8 card_faces[DECK_SIZE];
  U8 card_suits[DECK_SIZE];

  RandomOrderU8(NUM_SUITS, DECK_SIZE/NUM_SUITS, card_suits);
  RandomOrderU8(NUM_FACES, DECK_SIZE/NUM_FACES, card_faces);

  
}

U0 DrawIt(CTask *task, CDC *dc)
{
  dc->color = ROPF_DITHER + GREEN + 16 << DKGRAY;
  GrFloodFill(dc, 0, 0);
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
  DocCursor;
  DocClear;

  Init;
  Fs->draw_it = &DrawIt;
  Loop;
  
  SettingsPop;
}

Klondike;

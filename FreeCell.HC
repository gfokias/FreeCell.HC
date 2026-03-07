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
#define FACE_J 10
#define FACE_Q 11
#define FACE_K 12
#define NUM_FACES 13

#define DECK_SIZE (NUM_SUITS * NUM_FACES)

#define NUM_CASCADES 8
#define CASCADE_LENGTH_INITIAL 7
#define CASCADE_LENGTH (NUM_FACES + 1) /* Last one is always -1 */ 

#define SHUFFLES 4
#define GCDS 5

#define CARD_WIDTH 48
#define CARD_HEIGHT 64
#define PADDING 76
#define PADDING_X 64
#define PADDING_Y (CARD_HEIGHT/2)

#define MIN_CLICK_DISTANCE 0.1
#define SLEEP_TIME 50

U8 card_faces[DECK_SIZE];
U8 card_suits[DECK_SIZE];

static I64 NULL_CARD = -1; /* Needed for easy dereferences */

CD2I64 sel_offset;
I64 *sel_card = &NULL_CARD;

/* Contains card index */
I64 piles[NUM_CASCADES][CASCADE_LENGTH];

static U8 SUIT_BLACK[NUM_SUITS] = { TRUE, FALSE, FALSE, TRUE };
static U8 SUIT_CHAR[NUM_SUITS] = "CDHS";
static U8 FACE_CHAR[NUM_FACES] = "A23456789XJQK";

static U8 *message = "";

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

  MemSetI64(piles, -1, sizeof(piles)/sizeof(I64));
  
  for (i = 0; i < NUM_CASCADES/2; i++) {
    for (j = 0; j < CASCADE_LENGTH_INITIAL - 1; j++) {
      piles[i][j] = card++;
    }
    piles[i][CASCADE_LENGTH - 1] = -1;
  }

  for (i = NUM_CASCADES/2; i < NUM_CASCADES; i++) {
    for (j = 0; j < CASCADE_LENGTH_INITIAL; j++) {
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

U0 DrawCardOutline(CDC *dc, U64 x, U64 y)
{
  GrLine(dc, x, y, x, y + CARD_HEIGHT);
  GrLine(dc, x, y, x + CARD_WIDTH, y); 
  GrLine(dc, x + CARD_WIDTH, y, x + CARD_WIDTH, y + CARD_HEIGHT);
  GrLine(dc, x, y + CARD_HEIGHT, x + CARD_WIDTH, y + CARD_HEIGHT);
}

U0 DrawCard(CDC *dc, U64 x, U64 y, U64 card)
{
  static U8 buffer[3];
 
  dc->color = BLACK;
  DrawCardOutline(dc, x, y);

  dc->color = WHITE;
  GrRect(dc, x + 1, y + 1, CARD_WIDTH - 1, CARD_HEIGHT - 1);

  if (SUIT_BLACK[card_suits[card]]) {
    dc->color = BLACK;
  } else {
    dc->color = RED;
  }

  buffer[0] = SUIT_CHAR[card_suits[card]];
  buffer[1] = FACE_CHAR[card_faces[card]];
  buffer[2] = '\0';
  
  GrTextBox3(dc, x + 2, y + 2, 0, buffer);
}

U0 DrawCards(CDC *dc)
{
  U64 i, j, x, y, card;
 
  for (i = 0; i < NUM_CASCADES; i++) {
    x = PADDING + PADDING_X * i;
    y = PADDING - PADDING_Y;
    
    for (j = 0; j < CASCADE_LENGTH; j++) { 
      card = piles[i][j];

      if (card != -1 && card != *sel_card) {
	y += PADDING_Y;
	DrawCard(dc, x, y, card);
      }
    }   
  }

  if (sel_card == &NULL_CARD) return;
  DrawCard(dc, ms.pos.x + sel_offset.x, ms.pos.y + sel_offset.y, *sel_card);
}

U0 DrawIt(CTask *task, CDC *dc)
{
  U8 *b;
  DrawBackground(dc);
  DrawCards(dc);
  GrPrint(dc, 0, 0, "%s", message);
}

U0 GetHoveringCascade(I64 *cascade, I64 *last_card = NULL, I64 offset_x = 0, I64 offset_y = 0)
{ /* Last card is set to -1 if not hovering over it */
  static I64 i, j;

  /* TODO: Use math instead of for loop if too slow */
  for (i = 0; i < NUM_CASCADES; i++) {
    if (ms.pos.x + offset_x > PADDING + PADDING_X * i &&
	ms.pos.x + offset_x < PADDING + PADDING_X * i + CARD_WIDTH) {
      *cascade = i;
      
      if (last_card == NULL) return;
      
      for (j = 0; piles[i][j] != -1; j++);
      j--;

      if (ms.pos.y + offset_y < PADDING + PADDING_Y * j ||
	  ms.pos.y + offset_y > PADDING + PADDING_Y * j + CARD_HEIGHT) {
	*last_card = -1;
      } else {
	*last_card = j;
      }

      return;
    }
  }
}

U0 TrySelectCard()
{
  static I64 i, j;

  GetHoveringCascade(&i, &j);

  if (i == -1 || j == -1) return;
  
  sel_card = &piles[i][j];
  sel_offset.x = PADDING + PADDING_X * i - ms.pos.x;
  sel_offset.y = PADDING + PADDING_Y * j - ms.pos.y;
}

Bool ValidMove(I64 from, I64 to)
{
  return card_faces[from] == (card_faces[to] - 1)
    && SUIT_BLACK[card_suits[from]] != SUIT_BLACK[card_suits[to]];
}

U0 TryReleaseCard()
{
  static I64 i, j;

  GetHoveringCascade(&i, &j, sel_offset.x, sel_offset.y);

  if (i == -1 || j == -1 || !ValidMove(*sel_card, piles[i][j])) return;

  piles[i][j + 1] = *sel_card;
  *sel_card = -1;
  sel_card = &NULL_CARD;
}

U0 HandleSelection()
{
  if (ms.lb) {
    if (sel_card != &NULL_CARD) return;
    TrySelectCard;
  } else {
    if (sel_card == &NULL_CARD) return;
    TryReleaseCard;
    sel_card = &NULL_CARD;
  }
}

U0 Loop()
{
  I64 ch;

  while (TRUE) {
    HandleSelection;

    if (ScanKey(&ch)) {
      if (ch.u8[0] == CH_ESC) return;
    }
    
    Sleep(SLEEP_TIME);
  }
  
}

U0 FreeCell()
{
  SettingsPush;

  AutoComplete;
  DocCursor;
  WinBorder;
  WinMax;
  
  Fs->draw_it = &DrawIt;

  Init;
  Loop;
  
  SettingsPop;
}

FreeCell;

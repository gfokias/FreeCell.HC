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

#define NUM_CELLS 4
#define NUM_FOUNDATIONS NUM_SUITS

#define SHUFFLES 4

#define CARD_WIDTH 48
#define CARD_HEIGHT 64
#define CELL_PADDING 32

#define CARD_PADDING_X 76
#define CARD_PADDING_Y 128
#define CARD_DIST_X 64
#define CARD_DIST_Y (CARD_HEIGHT/4)

#define NUM_MOVES 100
#define SLEEP_TIME 50

class Move
{
  I64 *from;
  I64 *to;
};

U8 card_faces[DECK_SIZE];
U8 card_suits[DECK_SIZE];

static I64 NULL_CARD = -1; /* Needed for easy dereferences */

CD2I64 sel_offset;
I64 *sel_card = &NULL_CARD;

I64 piles[NUM_CASCADES][CASCADE_LENGTH]; /* Contains card indexes */
I64 cells[NUM_CELLS];
I64 foundations[NUM_FOUNDATIONS];

Move moves[NUM_MOVES];
I64 num_moves;

static U8 SUIT_BLACK[NUM_SUITS] = { TRUE, FALSE, FALSE, TRUE };
static U8 SUIT_CHAR[NUM_SUITS] = "CDHS";
static U8 FACE_CHAR[NUM_FACES] = "A23456789XJQK";

U8 *SemiRandomOrderU8(U64 n, U8 times = 1, U8 *order = NULL)
{ /* n should be prime or 4. If gcd(I, n) == 1 then {K*I % n, K = 0,1,...} == {1,2,...,n} */
  U64 i, j, step;

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
  I64 i, j, card;

  card = 0;
  num_moves = 0;
  
  MemSetI64(piles, NULL_CARD, sizeof(piles)/sizeof(I64));
  MemSetI64(cells, NULL_CARD, sizeof(cells)/sizeof(I64));
  MemSetI64(foundations, NULL_CARD, sizeof(foundations)/sizeof(I64));
  
  SemiRandomOrderU8(NUM_SUITS, DECK_SIZE/NUM_SUITS, card_suits);
  SemiRandomOrderU8(NUM_FACES, DECK_SIZE/NUM_FACES, card_faces);
  
  for (i = 0; i < NUM_CASCADES/2; i++) {
    for (j = 0; j < CASCADE_LENGTH_INITIAL - 1; j++) {
      piles[i][j] = card++;
    }
    piles[i][CASCADE_LENGTH - 1] = NULL_CARD;
  }

  for (i = NUM_CASCADES/2; i < NUM_CASCADES; i++) {
    for (j = 0; j < CASCADE_LENGTH_INITIAL; j++) {
      piles[i][j] = card++;
    }
  }
}

U0 DrawBackground(CDC *dc)
{
  I64 x, y, i, j, max;

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

U0 DrawCardOutline(CDC *dc, I64 x, I64 y)
{
  GrLine(dc, x, y, x, y + CARD_HEIGHT);
  GrLine(dc, x, y, x + CARD_WIDTH, y); 
  GrLine(dc, x + CARD_WIDTH, y, x + CARD_WIDTH, y + CARD_HEIGHT);
  GrLine(dc, x, y + CARD_HEIGHT, x + CARD_WIDTH, y + CARD_HEIGHT);
}

U0 DrawCard5(CDC *dc, I64 x, I64 y, I64 suit, I64 face)
{
  U8 buffer[3];
 
  dc->color = BLACK;
  DrawCardOutline(dc, x, y);
  
  dc->color = WHITE;
  GrRect(dc, x + 1, y + 1, CARD_WIDTH - 1, CARD_HEIGHT - 1);

  if (SUIT_BLACK[suit]) {
    dc->color = BLACK;
  } else {
    dc->color = RED;
  }

  buffer[0] = SUIT_CHAR[suit];
  buffer[1] = FACE_CHAR[face];
  buffer[2] = '\0';
  
  GrTextBox3(dc, x + 2, y + 2, 0, buffer);
}

U0 DrawCard4(CDC *dc, I64 x, I64 y, I64 card)
{
  DrawCard5(dc, x, y, card_suits[card], card_faces[card]);
}

U0 DrawCascadeCards(CDC *dc)
{
  U64 i, j, x, y, card;
 
  for (i = 0; i < NUM_CASCADES; i++) {
    x = CARD_PADDING_X + CARD_DIST_X * i;
    y = CARD_PADDING_Y - CARD_DIST_Y;
    
    for (j = 0; j < CASCADE_LENGTH; j++) { 
      card = piles[i][j];
      y += CARD_DIST_Y;
      if (card == NULL_CARD || card == *sel_card) break;
      DrawCard4(dc, x, y, card);
    }

    if (j == 0) {
      dc->color = LTGRAY;
      DrawCardOutline(dc, x, y);
    }
  }
}

U0 DrawSelectedCard(CDC *dc)
{
  if (sel_card == &NULL_CARD) return;
  DrawCard4(dc, ms.pos.x + sel_offset.x, ms.pos.y + sel_offset.y, *sel_card);
}

I64 DrawTopCardArray(CDC *dc, I64 x, I64 *card_array, I64 card_length)
{
  U64 i;

  x -= CARD_DIST_X;
  
  for (i = 0; i < card_length; i++) {
    x += CARD_DIST_X;
    
    dc->color = LTGRAY;

    if (card_array[i] == NULL_CARD || sel_card == &card_array[i]) {
      DrawCardOutline(dc, x, CELL_PADDING);
    } else {
      DrawCard4(dc, x, CELL_PADDING, card_array[i]);
    }
  }
  
  return x + CARD_DIST_X;
}

U0 DrawCellsAndFoundations(CDC *dc)
{
  I64 x;
  
  x = DrawTopCardArray(dc, CELL_PADDING, cells, NUM_CELLS);
  DrawTopCardArray(dc, CELL_PADDING + x, foundations, NUM_FOUNDATIONS);
}

U0 DrawIt(CTask *_task, CDC *dc)
{
  DrawBackground(dc);
  DrawCellsAndFoundations(dc);
  DrawCascadeCards(dc);
  DrawSelectedCard(dc);
  
  dc->color = WHITE;
  GrPrint(dc, 16, 0, "Moves: %d\n", num_moves);
}

Bool CardBoundsX(I64 x, I64 offset_x = 0) {
  return ms.pos.x + offset_x > x && ms.pos.x + offset_x < x + CARD_WIDTH; 
}

Bool CardBoundsY(I64 y, I64 offset_y = 0) {
  return ms.pos.y + offset_y > y && ms.pos.y + offset_y < y + CARD_HEIGHT;
}

Bool GetHoveringCascade(I64 *cascade, I64 *last_card, I64 offset_x = 0, I64 offset_y = 0)
{ /* last_card is set to NULL_CARD if not hovering over it */
  I64 i, j;

  /* TODO: Use math instead of for loop if too slow */
  for (i = 0; i < NUM_CASCADES; i++) {
    if (CardBoundsX(CARD_PADDING_X + CARD_DIST_X * i, offset_x)) {
      *cascade = i;
      
      for (j = 0; piles[i][j] != NULL_CARD; j++);
      
      if (j == 0) {
	*last_card = NULL_CARD;
	return FALSE;
      }

      j--;

      if (CardBoundsY(CARD_PADDING_Y + CARD_DIST_Y * j, offset_y)) {
	*last_card = j;

	sel_offset.x = CARD_PADDING_X + CARD_DIST_X * i - ms.pos.x;
	sel_offset.y = CARD_PADDING_Y + CARD_DIST_Y * j - ms.pos.y;
	
	return TRUE;
      }
      
      *last_card = NULL_CARD;
      return FALSE;
    }
  }

  *cascade = -1;
  return FALSE;
}

Bool GetHoveringCell(I64 *cell)
{
  I64 i, x;

  if (!CardBoundsY(CELL_PADDING)) {
    return FALSE;
  }
  
  x = CELL_PADDING - CARD_DIST_X;
  
  for (i = 0; i < NUM_CELLS; i++) {
    x += CARD_DIST_X;

    if (CardBoundsX(x)) {
      *cell = i;

      sel_offset.x = CELL_PADDING + CARD_DIST_X * i - ms.pos.x;
      sel_offset.y = CELL_PADDING - ms.pos.y;

      return TRUE;
    }
  }

  return FALSE;
}

U0 TryMoveCardToFoundation()
{
  I64 i, j, card;
  
  if (!GetHoveringCascade(&i, &j)) return;

  card = piles[i][j];
  
  if (card_faces[card]);
  
}

U0 TrySelectCard()
{
  I64 i, j;

  if (GetHoveringCascade(&i, &j)) {
    sel_card = &piles[i][j];
  } else if (GetHoveringCell(&i)) {
    sel_card = &cells[i];
  }
}

Bool ValidMove(I64 from, I64 to)
{
  if (from == FACE_K && to == NULL_CARD) return TRUE;
  return
    from != NULL_CARD && to != NULL_CARD
     && card_faces[from] == (card_faces[to] - 1)
     && SUIT_BLACK[card_suits[from]] != SUIT_BLACK[card_suits[to]];
}

U0 MoveCards(I64 *from, I64 *to)
{
  Move *move = &moves[num_moves++ % NUM_MOVES];
  move->from = from;
  move->to = to;
  SwapI64(from, to);
}

U0 UndoMove()
{
  if (num_moves == 0) return;
  Move *move = &moves[--num_moves % NUM_MOVES];
  SwapI64(move->from, move->to);
}

U0 TryReleaseCard()
{
  I64 i, j;

  GetHoveringCascade(&i, &j, sel_offset.x, sel_offset.y);
  if (i == -1) GetHoveringCascade(&i, &j);
  if (i == -1) return;

  if (j == NULL_CARD) {
    if (!ValidMove(*sel_card, NULL_CARD)) return;
    j = -1; /* Redundant */
  } else {
    if (!ValidMove(*sel_card, piles[i][j])) return;
  }

  MoveCards(&piles[i][j + 1], sel_card);
}

I64 GetFreeCell()
{
  I64 cell;
  for (cell = 0; cell < NUM_CELLS; cell++) {
    if (cells[cell] == NULL_CARD) return cell;
  }
  return -1;
}

U0 TryCellCard()
{
  I64 i, j, cell;

  cell = GetFreeCell;
  if (cell == -1) return;
 
  GetHoveringCascade(&i, &j);
  if (i == -1 || j == NULL_CARD) return;
  
  MoveCards(&cells[cell], &piles[i][j]);
}

U0 HandleSelection()
{
  if (ms.lb) {
    if (sel_card != &NULL_CARD) return;

    if (!Bt(kbd.down_bitmap, SC_SHIFT)) {
      TrySelectCard;
    } else {
      TryMoveCardToFoundation;
    }
  } else if (ms.rb) {
    if (ms_last.rb) return;
    TryCellCard;
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
      if (ch.u8[0] == CH_ESC && !ms.left_dbl) return;
      if (ch.u8[0] == CH_BACKSPACE) UndoMove;
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

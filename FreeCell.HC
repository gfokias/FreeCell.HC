#define REGISTRY "GFokias/FreeCell"

RegDft(REGISTRY, "9999;\n");

#define SELECT_TYPE_NONE -1
#define SELECT_TYPE_SINGLE 0
#define SELECT_TYPE_CASCADE 1

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
#define CASCADE_LENGTH (2 * NUM_FACES + 1) /* Last one is always -1 */ 

#define NUM_CELLS 4
#define NUM_FOUNDATIONS NUM_SUITS

#define SHUFFLES 4

#define CARD_WIDTH 48
#define CARD_HEIGHT 64
#define CELL_PADDING 32
#define FOUNDATION_PADDING CELL_PADDING

#define CELL_START CELL_PADDING - CARD_DIST_X
#define FOUNDATION_START GR_WIDTH + CARD_DIST_X - FOUNDATION_PADDING - CARD_WIDTH

#define CARD_PADDING_X 76
#define CARD_PADDING_Y 128
#define CARD_DIST_X 64
#define CARD_DIST_Y (CARD_HEIGHT/4)

#define NUM_MOVES 1024
#define SLEEP_TIME 50

class Move
{
  Bool single;
  I64 *from;
  I64 *to;
};

U8 card_faces[DECK_SIZE];
U8 card_suits[DECK_SIZE];

static I64 NULL_CARD = -1; /* Needed for easy dereferences */

CD2I64 sel_offset;
I64 *sel_card = &NULL_CARD;
I64 sel_type;

I64 piles[NUM_CASCADES][CASCADE_LENGTH]; /* Contains card indexes */
I64 cells[NUM_CELLS];
I64 foundations[NUM_FOUNDATIONS][CASCADE_LENGTH];

Move moves[NUM_MOVES];
I64 num_moves;
I64 num_mass_moves; /* Cards that are moved en-masse */
F64 t0;

I64 best_moves;

Bool win;

static U8 SUIT_BLACK[NUM_SUITS] = { TRUE, FALSE, FALSE, TRUE };
static U8 SUIT_CHAR[NUM_SUITS] = "CDHS";
static U8 FACE_CHAR[NUM_FACES] = "A23456789XJQK";

U8 *SemiRandomOrderU8(U64 n, U64 times, U8 *order = NULL)
{ /* n should be prime or 4. If gcd(I, n) == 1 then {K*I % n, K = 0,1,...} == {1,2,...,n} */
  U64 i, j, step;

  if (order == NULL) {
    order = MAlloc(n);
    if (order == NULL) return NULL;
  }

  for (i = 0; i < n; i += n) {
    order[i] = RandU64 % n;
    step = 1 + RandU64 % (n - 1);
    
    /* Only works because n can only be 4 or 13. 13 is prime. 2 + 1 = 3 % 2 = 1 */
    if (step != 1) {
      if (n % step == 0) step++;
      if (n % step == 0) throw('BadNum');
    }
    
    for (j = 0; j < n * times; j++) {
      order[i + j] = (order[i + j - 1] + step) % n;
    }

  }
  
  for (j = 0; i < n * SHUFFLES; i++) {
    SwapU8(&order[i + Rand % n], &order[i + Rand % n]);
  }

  return order;
}

U0 Init()
{
  I64 i, j, card;

  win = FALSE;
  t0 = tS;
  card = 0;
  num_moves = 0;
  num_mass_moves = 0;
  best_moves = RegExe(REGISTRY);
  
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

Bool ValidMove(I64 from, I64 to)
{
  return
    card_faces[from] == FACE_K && to == NULL_CARD
    || from != NULL_CARD && to != NULL_CARD
    && card_faces[from] == (card_faces[to] - 1)
    && SUIT_BLACK[card_suits[from]] != SUIT_BLACK[card_suits[to]];
}

U0 DrawBackground(CDC *dc)
{
  /* God approved method. See $LK,"BomberGolf",A="FF:::/Demo/Games/BomberGolf.HC,ROPF_DITHER"$ */
  dc->color = ROPF_DITHER | GREEN << 16 | DKGRAY;
  GrRect3(dc, 0, 0, 0, dc->width, dc->height);
} 

U0 DrawCardOutline(CDC *dc, I64 x, I64 y, CColorROPU32 color = LTGRAY)
{
  dc->color = color;
  GrLine(dc, x, y, x, y + CARD_HEIGHT);
  GrLine(dc, x, y, x + CARD_WIDTH, y); 
  GrLine(dc, x + CARD_WIDTH, y, x + CARD_WIDTH, y + CARD_HEIGHT);
  GrLine(dc, x, y + CARD_HEIGHT, x + CARD_WIDTH, y + CARD_HEIGHT);
}

U0 DrawCard5(CDC *dc, I64 x, I64 y, I64 suit, I64 face)
{
  U8 buffer[3];
 
  DrawCardOutline(dc, x, y, BLACK);
  
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
  I64 i, j, x, y, card;
 
  for (i = 0; i < NUM_CASCADES; i++) {
    x = CARD_PADDING_X + CARD_DIST_X * i;
    y = CARD_PADDING_Y - CARD_DIST_Y;
    
    for (j = 0; j < CASCADE_LENGTH; j++) { 
      card = piles[i][j];
      y += CARD_DIST_Y;
      if (card == NULL_CARD) break;

      if (card != *sel_card) {
	DrawCard4(dc, x, y, card);
      } else {
	DrawCardOutline(dc, x, y);
	break;
      }
    }

    if (j == 0) {
      DrawCardOutline(dc, x, y);
    }
  }
}

U0 DrawSelectedCard(CDC *dc)
{
  I64 x, y, *card;
  if (sel_card == &NULL_CARD) return;

  x = ms.pos.x + sel_offset.x;
  y = ms.pos.y + sel_offset.y;
  
  DrawCard4(dc, x, y, *sel_card);
  if (sel_type != SELECT_TYPE_CASCADE) return;

  /* Works because CASCADE_LENGTH = NUM_FACES + 1*/
  for (card = sel_card + 1; *card != NULL_CARD; card++) {
    y += CARD_DIST_Y;
    DrawCard4(dc, x, y, *card);
  }
}

U0 DrawCells(CDC *dc)
{
  I64 x, i;

  x = CELL_START;
  
  for (i = 0; i < NUM_CELLS; i++) {
    x += CARD_DIST_X;
    
    if (cells[i] == NULL_CARD || sel_card == &cells[i]) {
      DrawCardOutline(dc, x, CELL_PADDING);
    } else {
      DrawCard4(dc, x, CELL_PADDING, cells[i]);
    }
  }
}

U0 DrawFoundations(CDC *dc)
{
  I64 x, i, j;

  x = FOUNDATION_START;
  
  for (i = 0; i < NUM_FOUNDATIONS; i++) {
    x -= CARD_DIST_X;

    /* Praying to God that this is not slow as molasses */
    for (j = 0; foundations[i][j] != NULL_CARD; j++);
    j--;
    
    if (sel_card == &foundations[i][j]) {
      j--;
      if (j == -2) throw('InvSel'); /* Should be impossible */
    }

    if (j == -1) {
      DrawCardOutline(dc, x, FOUNDATION_PADDING);
    } else {
      DrawCard4(dc, x, FOUNDATION_PADDING, foundations[i][j]);
    }
  }
}

U0 DrawIt(CTask *_task, CDC *dc)
{
  DrawBackground(dc);
  DrawCells(dc);
  DrawFoundations(dc);
  DrawCascadeCards(dc);
  DrawSelectedCard(dc);
  
  dc->color = WHITE;
  
  GrPrint(dc, FONT_WIDTH, FONT_HEIGHT,
	  "Time: %f\n"
	  "Moves: %d - Least moves: %d",
	  tS - t0,
	  num_moves - num_mass_moves,
	  best_moves);
  GrPrint(dc, FONT_WIDTH, GR_HEIGHT - 6 * FONT_HEIGHT,
	  "Left-click to grab a card\n"
	  "Right-click to move a card to a cell\n"
	  "Shift + Left-click to move a card to its corresponding foundation\n"
	  "Backspace to undo the last move");
}

Bool CardBoundsX(I64 x, I64 offset_x = 0, I64 width = CARD_WIDTH) {
  return ms.pos.x + offset_x > x && ms.pos.x + offset_x < x + width; 
}

Bool CardBoundsY(I64 y, I64 offset_y = 0, I64 height = CARD_HEIGHT) {
  return ms.pos.y + offset_y > y && ms.pos.y + offset_y < y + height;
}

Bool GetHoveringCascade(I64 *cascade, I64 *card, I64 offset_x = 0,
			I64 offset_y = 0, Bool single_card = TRUE)
{ /* Returns TRUE when hovering over a card */
  I64 i, j, x, y;

  /* TODO: Use math instead of for loop if too slow */
  for (i = 0; i < NUM_CASCADES; i++) {
    x = CARD_PADDING_X + CARD_DIST_X * i;
    
    if (CardBoundsX(x, offset_x)) {
      *cascade = i;
      
      for (j = 0; piles[i][j] != NULL_CARD; j++);
      
      if (j == 0) {
	*card = NULL_CARD;
	return FALSE;
      }

      j--;
      y = CARD_PADDING_Y + CARD_DIST_Y * j;
      
      /* Single selection */
      if (CardBoundsY(y, offset_y)) {
	*card = j;

	sel_offset.x = x - ms.pos.x;
	sel_offset.y = y - ms.pos.y;
	
	return TRUE;
      }

      if (single_card == FALSE) {
	/* Multiple selection */
	for (j--; j >= 0; j--) {
	  if (!ValidMove(piles[i][j + 1], piles[i][j])) break;

	  y -= CARD_DIST_Y; 

	  if (CardBoundsY(y, offset_y, CARD_DIST_Y)) {
	    *card = j;

	    sel_offset.x = x - ms.pos.x;
	    sel_offset.y = y - ms.pos.y;

	    return TRUE;
	  }
	}
      }
      
      *card = NULL_CARD;
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
  
  x = CELL_START;
  
  for (i = 0; i < NUM_CELLS; i++) {
    x += CARD_DIST_X;

    if (CardBoundsX(x)) {
      *cell = i;

      sel_offset.x = x - ms.pos.x;
      sel_offset.y = CELL_PADDING - ms.pos.y;

      return TRUE;
    }
  }

  return FALSE;
}

Bool GetHoveringFoundation(I64 *foundation, I64 *last_card)
{
  I64 i, j, x;

  if (!CardBoundsY(FOUNDATION_PADDING)) {
    return FALSE;
  }
  
  x = FOUNDATION_START;

  for (i = 0; i < NUM_FOUNDATIONS; i++) {
    x -= CARD_DIST_X;

    if (CardBoundsX(x)) {
      *foundation = i;

      for (j = 0; foundations[i][j] != NULL_CARD; j++); 
      if (j == 0) return FALSE;

      *last_card = j - 1;
 
      sel_offset.x = x - ms.pos.x;
      sel_offset.y = FOUNDATION_PADDING - ms.pos.y;

      return TRUE;
    }
  }

  return FALSE;
}

I64 TrySelectCard(I64 **card, Bool single = FALSE)
{
  I64 i, j;
 
  /* All of these functions also set sel_offset */
  if (GetHoveringCell(&i)) {
    *card = &cells[i];
    return SELECT_TYPE_SINGLE;
  }

  if (GetHoveringFoundation(&i, &j)) {
    *card = &foundations[i][j];
    return SELECT_TYPE_SINGLE;
  }

  if (GetHoveringCascade(&i, &j,,, single)) {
    *card = &piles[i][j];
    return SELECT_TYPE_CASCADE;
  }

  *card = &NULL_CARD;

  return SELECT_TYPE_NONE; 
}

U0 MoveCards(I64 *from, I64 *to, Bool single = TRUE)
{
  Move *move = &moves[num_moves++ % NUM_MOVES];
  move->from = from;
  move->to = to;
  move->single = single;
  SwapI64(from, to);
  if (!single) num_mass_moves++;
}

U0 UndoMove()
{
  if (num_moves == 0) return;

  Move *move = &moves[--num_moves % NUM_MOVES];
  SwapI64(move->from, move->to);

  if (!move->single) {
    num_mass_moves--;
    UndoMove;
  }
}

U0 TryMoveCardToFoundation()
{
  I64 i, j, *card, face, suit;
  
  if (TrySelectCard(&card, TRUE) == SELECT_TYPE_NONE) return;

  face = card_faces[*card];
  suit = card_suits[*card];

  if (foundations[suit][face] != NULL_CARD) return;
  if (face != FACE_A && foundations[suit][face - 1] == NULL_CARD) return;

  MoveCards(card, &foundations[suit][face]);
}

Bool HasWon()
{
  I64 i;
  
  for (i = 0; i < NUM_FOUNDATIONS; i++) {
    if (foundations[i][FACE_K] == NULL_CARD) return FALSE;
  }

  return TRUE;
}

U0 TryCascadeCard()
{
  I64 i, j, *card;

  GetHoveringCascade(&i, &j, sel_offset.x, sel_offset.y);
  if (i == -1) GetHoveringCascade(&i, &j);
  
  if (j == NULL_CARD && piles[i][0] == NULL_CARD) {
    /* The card snaps into place from any height, but who cares really */
    if (!ValidMove(*sel_card, NULL_CARD)) return; 
    j = -1; /* Redundant */
  } else {
    if (!ValidMove(*sel_card, piles[i][j])) return;
  }

  MoveCards(&piles[i][++j], sel_card);

  if (sel_type != SELECT_TYPE_CASCADE) return;

  for (card = sel_card + 1; *card != NULL_CARD; card++) {
    MoveCards(&piles[i][++j], card, FALSE);
  }
}

I64 GetFreeCell()
{
  I64 cell;
  for (cell = 0; cell < NUM_CELLS; cell++) {
    if (cells[cell] == NULL_CARD) return cell;
  }
  return -1;
}

Bool TryCellCard()
{
  I64 i, j, cell, *card;

  cell = GetFreeCell;
  if (cell == -1) return FALSE;
 
  if (TrySelectCard(&card, TRUE) == SELECT_TYPE_NONE) return FALSE;
  
  MoveCards(card, &cells[cell]);
  return TRUE;
}

U0 HandleSelection()
{
  static Bool debounce;

  if (debounce) {
    debounce = ms.lb || ms.rb;
    return;
  }
  
  if (ms.lb) {
    if (sel_card != &NULL_CARD) return;

    if (!Bt(kbd.down_bitmap, SC_SHIFT)) {
      sel_type = TrySelectCard(&sel_card);
    } else {
      TryMoveCardToFoundation;
      win = HasWon;
    }
  } else if (ms.rb) {
    debounce = TryCellCard;
  } else {
    if (sel_card == &NULL_CARD) return;
    TryCascadeCard;
    sel_card = &NULL_CARD;
  }
}

U0 Loop()
{
  I64 ch;

  while (TRUE) {
    HandleSelection;
    
    if (ScanKey(&ch)) {
      if (ch.u8[0] == CH_ESC && !ms.left_dbl && !ms.right_dbl) return;
      if (ch.u8[0] == CH_BACKSPACE) UndoMove;
    }

    if (win) {
      best_moves = MinI64(moves, best_moves);
      PopUpOk("You Win!");
      return;
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

  RegWrite(REGISTRY, "%d;\n", best_moves); 
  
  SettingsPop;
}

FreeCell;

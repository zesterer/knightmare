namespace knightmare
{
	namespace UI
	{
		public class BoardArea : Gtk.DrawingArea
		{
			public Window mother;
			public Application root;
			
			public double cell_width;
			public double board_scale;
			
			public bool draw_selected = false;
			public int select_pos_x = 0;
			public int select_pos_y = 0;
			public DynamicList<Core.Move> potential_moves;
			
			Cairo.ImageSurface piece_surface;
			
			public BoardArea(Window mother)
			{
				this.mother = mother;
				this.root = this.mother.root;
				
				this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
				this.button_press_event.connect(this.buttonPress);
				this.draw.connect(this.display);
				
				this.resetResolution(32);
				
				//Keep the board in the centre
				this.set_hexpand(true);
				this.set_vexpand(true);
				this.set_halign(Gtk.Align.CENTER);
				this.set_valign(Gtk.Align.CENTER);
				
				this.setPieces();
			}
			
			public void setPieces(string filename = "resources/pieces.png")
			{
				this.piece_surface = new Cairo.ImageSurface.from_png(filename);
			}
			
			public void resetResolution(int cell_width)
			{
				//Arbitary for now
				this.cell_width = cell_width;
				//64 is the base size
				this.board_scale = this.cell_width / 64;
				
				//Set the minimum size of the widget according to the board size
				this.width_request = (int)this.cell_width * 10; //The edges
				this.height_request = (int)this.cell_width * 10; //The edges
				
				this.queue_draw();
			}
		
			public bool display(Cairo.Context context)
			{
				this.drawBoard(context);
				
				this.drawSelected(context);
				
				this.drawPieces(context);
			
				return true;
			}
			
			public bool buttonPress(Gdk.EventButton event)
			{
				int pos_x, pos_y;
				
				pos_x = (int)(event.x / this.cell_width) - 1;
				pos_y = (int)(event.y / this.cell_width) - 1;
				
				if (pos_x >= 0 && pos_x <= 7 && pos_y >= 0 && pos_y <= 7)
				{
					if (!draw_selected)
					{
						this.select_pos_x = pos_x;
						this.select_pos_y = pos_y;
						
						this.draw_selected = true;
						
						this.potential_moves = this.mother.game.board.getPieceMoves((int8)this.select_pos_x, (int8)this.select_pos_y);
					}
					else
					{
						Core.Move move = new Core.Move(this.mother.game.board, (int8)this.select_pos_x, (int8)this.select_pos_y, (int8)pos_x, (int8)pos_y);
						move.apply();
						
						this.draw_selected = false;
					}
					
					this.queue_draw();
				}
				
				return false;
			}
			
			public void drawSelected(Cairo.Context context)
			{
				if (draw_selected)
				{
					//Draw the board border
					context.rectangle((this.select_pos_x + 1) * this.cell_width, (this.select_pos_y + 1) * this.cell_width, this.cell_width, this.cell_width);
					Gdk.cairo_set_source_rgba(context, {0.4, 0.3, 0.3, 0.4});
					context.fill();
					
					for (int count = 0; count < this.potential_moves.length; count ++)
					{
						if (this.mother.game.board.data[this.potential_moves[count].to_x, this.potential_moves[count].to_y] != 0x00)
							Gdk.cairo_set_source_rgba(context, {0.3, 0.6, 0.6, 0.4});
						else
							Gdk.cairo_set_source_rgba(context, {0.3, 0.6, 0.3, 0.4});
						
						//Draw the board border
						context.rectangle((this.potential_moves[count].to_x + 1) * this.cell_width, (this.potential_moves[count].to_y + 1) * this.cell_width, this.cell_width, this.cell_width);
						context.fill();
					}
				}
			}
			
			public void drawBoard(Cairo.Context context)
			{
				//Draw the board border
				context.rectangle(0, 0, 10 * this.cell_width, 10 * this.cell_width);
				Gdk.cairo_set_source_rgba(context, {0.7, 0.6, 0.4, 1.0});
				context.fill();
				
				//Draw the board background
				context.rectangle(this.cell_width, this.cell_width, 8 * this.cell_width, 8 * this.cell_width);
				Gdk.cairo_set_source_rgba(context, {0.9, 0.8, 0.7, 1.0});
				context.fill();
				
				//Draw the grid
				for (int pos = 0; pos < 32; pos ++)
				{
					int add = 0;
					
					if ((pos / 4) % 2 == 0)
						add = (int)this.cell_width;
					
					context.rectangle((pos % 4 + 0.5) * this.cell_width * 2 + add, (pos / 4 + 1) * this.cell_width, this.cell_width, this.cell_width);
				}
				Gdk.cairo_set_source_rgba(context, {0.2, 0.2, 0.2, 1.0});
				context.fill();
				
				//Draw the text
				context.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
				context.set_font_size((int)(40.0 * this.board_scale));
				
				string[] letters = {"a", "b", "c", "d", "e", "f", "g", "h"};
				string[] numbers = {"8", "7", "6", "5", "4", "3", "2", "1"};
				Cairo.TextExtents extents;
				for (int a = 0; a < letters.length; a ++)
				{
					//Draw the letters
					context.text_extents(letters[a], out extents);
					
					//top side
					context.move_to((a + 1.5) * this.cell_width - (extents.width / 2 + extents.x_bearing), 0.5 * this.cell_width - (extents.height / 2 + extents.y_bearing));
					context.show_text(letters[a]);
					
					//bottom side
					context.move_to((a + 1.5) * this.cell_width - (extents.width / 2 + extents.x_bearing), 9.5 * this.cell_width - (extents.height / 2 + extents.y_bearing));
					context.show_text(letters[a]);
					
					//Draw the numbers
					context.text_extents(numbers[a], out extents);
					
					//left side
					context.move_to(0.5 * this.cell_width - (extents.width / 2 + extents.x_bearing), (a + 1.5) * this.cell_width - (extents.height / 2 + extents.y_bearing));
					context.show_text(numbers[a]);
					
					//right side
					context.move_to(9.5 * this.cell_width - (extents.width / 2 + extents.x_bearing), (a + 1.5) * this.cell_width - (extents.height / 2 + extents.y_bearing));
					context.show_text(numbers[a]);
				}
			}
			
			public void drawPieces(Cairo.Context context)
			{
				for (int8 x = 0; x < 8; x ++)
				{
					for (int8 y = 0; y < 8; y ++)
					{
						Core.Piece.Piece? piece = Core.Piece.kind[this.mother.game.board.data[x, y]];
						if (piece != null)
						{
							this.drawPiece(context, piece.kind, piece.colour, x, y);
						}
					}
				}
			}
			
			public void drawPiece(Cairo.Context context, Core.Piece.Kind kind, Core.Piece.Colour colour, int x, int y)
			{
				int colour_modifier = 0;
				if (colour == Core.Piece.Colour.WHITE)
					colour_modifier = 128; //Push the coordinates up
				
				int[2] pos;
				switch(kind)
				{
					case (Core.Piece.Kind.PAWN):
						pos = {128, 64};
						break;
					case (Core.Piece.Kind.ROOK):
						pos = {128, 0};
						break;
					case (Core.Piece.Kind.KNIGHT):
						pos = {64, 0};
						break;
					case (Core.Piece.Kind.BISHOP):
						pos = {64, 64};
						break;
					case (Core.Piece.Kind.QUEEN):
						pos = {0, 64};
						break;
					case (Core.Piece.Kind.KING):
						pos = {0, 0};
						break;
					default:
						pos = {0, 0};
						break;
				}
				//Draw the piece
				Cairo.Surface piece = new Cairo.Surface.for_rectangle(this.piece_surface, pos[0], pos[1] + colour_modifier, 64, 64);
				
				context.scale(this.board_scale, this.board_scale);
				context.set_source_surface(piece, (x + 1) * 64, (y + 1) * 64);
				context.scale(1.0 / this.board_scale, 1.0 / this.board_scale);
				context.paint();
			}
		}
	}
}

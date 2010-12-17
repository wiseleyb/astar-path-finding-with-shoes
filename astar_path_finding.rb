module AStarPathFinding
  
  BOARD_SIZE = [20,20]
  PIECE_WIDTH  = 30
  PIECE_HEIGHT = 30
  TOP_OFFSET = 30
  LEFT_OFFSET = 30

  class PathFinder
    attr_accessor :rows, :cols, :board, :grid

    def initialize(board)
      @rows = BOARD_SIZE.first
      @cols = BOARD_SIZE.last
      @board = board
      @grid = @board.board #Array.new(@rows) do; Array.new(@cols) do; rand(10) < 8 ? 0 : 1; end; end
    end

    def adjacency(spot = [0,0])
      # puts "adj #{spot.join(",")}"
      x = spot.first; y = spot.last
      res = []
      (-1..1).each do |i|
        (-1..1).each do |j|
          newspot = [x + i, y + j]
          # puts "#{x+i} #{y+j}"
          res << newspot if x+i >= 0 && x+i < @rows && y+j >= 0 && y+j < @cols
        end
      end
      az = res.collect {|r| "[" + r.join(",") + "] "}
      # puts "adj out #{az.join}"
      return res
    end

    def cost(spot = [0,0], newspot = [0,0])
      # puts "cost #{spot.join(",")} #{newspot.join(",")}"
      @grid[newspot.first][newspot.last].to_i * 900
    end

    def distance(goal = [0,0], spot = [0,0])
      dist = (goal.first - spot.first).abs + (goal.last - spot.last).abs
      # puts "dist #{goal.join(",")} #{spot.join(",")}  #{dist}"
      return dist
    end

    # def puts_grid
    #   @grid.each do |c|
    #     puts c.join(" ")
    #   end
    # end

    def run
      spot_start = @board.locate(2)
      spot_end = @board.locate(3)
      a = AStar.new(method("adjacency"), method("cost"), method("distance"))
      res = a.find_path(spot_start, spot_end)
      res.each do |spot|
        @grid[spot.first][spot.last] = 4 if @grid[spot.first][spot.last] == 0
      end
      return @grid
    end
  end


  class AStar

    def initialize(adjacency_func, cost_func, distance_func)
      @adjacency = adjacency_func
      @cost = cost_func
      @distance = distance_func
    end

    def find_path(start, goal)
      been_there = {}
      pqueue = PriorityQueue.new
      pqueue << [1, [start, [], 0]]
      while !pqueue.empty?
        spot, path_so_far, cost_so_far = pqueue.next
        next if been_there[spot]
        newpath = path_so_far + [spot]
        return newpath if (spot == goal)
        been_there[spot] = 1
        @adjacency.call(spot).each do |newspot|
          next if been_there[newspot]
          tcost = @cost.call(spot, newspot)
          next unless tcost
          newcost = cost_so_far + tcost
          pqueue << [newcost + @distance.call(goal, newspot),
                     [newspot, newpath, newcost]]
        end
      end
      return nil
    end   

    class PriorityQueue
      def initialize
        @list = []
      end
      def add(priority, item)
        @list << [priority, @list.length, item]
        @list.sort!
        self
      end
      def <<(pritem)
        add(*pritem)
      end
      def next
        @list.shift[2]
      end
      def empty?
        @list.empty?
      end
    end

  end
  
  class Board
    
    attr_accessor :board
    
    def initialize
      @board         = new_board
    end

    def new_board
      Array.new(BOARD_SIZE[0]) do # build each cols L to R
        Array.new(BOARD_SIZE[1]) do # insert cells in each col
          0
        end
      end
    end
        
    def total_squares
      BOARD_SIZE[0] * BOARD_SIZE[1]
    end

    def locate(val)
      @board.each_with_index { |row_array, row| 
        row_array.each_with_index { |col_array, col| 
          return [row,col] if @board[row][col] == val
        } 
      }
      return false
    end

    def clear(val)
      @board.each_with_index { |row_array, row| 
        row_array.each_with_index { |col_array, col| 
          @board[row][col] = 0 if @board[row][col] == val
        } 
      }
    end
      
  end # class

  def draw_board
    clear do
      background black
      stack :margin => LEFT_OFFSET do
        # fill rgb(0, 190, 0)
        fill black
        rect :left => 0, :top => 0, :width => (BOARD_SIZE.first) * PIECE_WIDTH, :height => (BOARD_SIZE.last) * PIECE_HEIGHT

        BRD.board.each_with_index do |col, col_index|
          col.each_with_index do |cell, row_index|
            left, top = left_top_corner_of_piece(col_index, row_index)
            left = left - LEFT_OFFSET
            top = top - TOP_OFFSET
            # fill rgb(0, 440, 0, 90)
            strokewidth 1
            stroke rgb(0, 100, 0)
            fill black
            rect :left => left, :top => top, :width => PIECE_WIDTH, :height => PIECE_HEIGHT
            
            if cell != 0
              strokewidth 0

              # fill red
              # oval(left, top, 3, 3)

              # # fill (cell == 1 ? rgb(100,100,100) : rgb(155,155,155))
              fill rgb(100, 100, 100)
              oval(left+3, top+4, PIECE_WIDTH-10, PIECE_HEIGHT-10)
              # 
              # fill (cell == 1 ? black : white)
              clr = case cell
                    when 4
                      yellow
                    when 3
                      red
                    when 2
                      green
                    else
                      white
                    end
              fill clr
              oval(left+5, top+5, PIECE_WIDTH-10, PIECE_HEIGHT-10)
              
              fill black
            end
            
          end
        end
      end
      stack :margin_top =>  590, :margin_left => 30 do
        para " S - places a start piece; E - places an end place; R - runs the path finder; C - clears the path; N - clears the board", :stroke => white
      end
    end
  end

  def find_piece(x,y)
    BRD.board.each_with_index { |row_array, row| 
      row_array.each_with_index { |col_array, col| 
        left, top = left_top_corner_of_piece(col, row).map { |i| i}
        right, bottom = right_bottom_corner_of_piece(col, row).map { |i| i}
        return [col, row] if x >= left && x <= right && y >= top && y <= bottom
      } 
    }
    return false
  end
  
  def lay_piece(c=[0,0], val = 1)
    x = c.first; y = c.last
    BRD.board[x][y] = BRD.board[x][y] > 0 ? 0 : val
  end
  
  def left_top_corner_of_piece(a,b)
    [(a*PIECE_WIDTH+LEFT_OFFSET), (b*PIECE_HEIGHT+TOP_OFFSET)]
  end

  def right_bottom_corner_of_piece(a,b)
    left_top_corner_of_piece(a,b).map { |coord| coord + PIECE_WIDTH }
  end

  BRD = Board.new
  
end # module

Shoes.app :width => (20 + 3) * 30, :height =>  (20 + 4) * 30 do
  extend AStarPathFinding
  draw_board

  click { |button, x, y| 
    if coords = find_piece(x,y)
     begin
        val = @start ? 2 : @end ? 3 : 1
        lay_piece(coords, val)
        @start = false
        @end = false
        draw_board
     rescue => e
       draw_board
       alert(e.message)
     end
    else
      # alert("Not a piece.")
    end
  }

  coords = [0,0]
  motion do |x, y|
    if self.mouse.first == 1
      new_coords = find_piece(x,y)
      unless coords == new_coords || new_coords == false
        coords = new_coords
        lay_piece(coords)
        draw_board
      end
    end
  end
  
  keypress do |k|
    @start = false
    @end = false
    case k.downcase
    when "s"
      @start = true
    when "e"
      @end = true
    when "r"
      BRD.board = PathFinder.new(BRD).run
      draw_board
    when "n"
      BRD.board = BRD.new_board
      draw_board
    when "c"
      BRD.clear(4)
      draw_board
    end
  end
  
  
end
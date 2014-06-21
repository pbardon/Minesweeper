# encoding: utf-8

require 'yaml'

class String
  def red;            "\033[31m#{self}\033[0m" end
end

class Game
  
  def initialize
    @b = Board.new(9)
    @selector = [0,0]
    cursor([0,0])
  end
  
  def run
    lose = 823475
    num_bombs = @b.seed
    num_of_spaces = 81 - num_bombs
    until lose == nil
      revealed_squares = 0
      @b.render
      lose = selector_actions
      for i in 0..8
        for j in 0..8
          if @b[[i, j]].revealed != nil
            revealed_squares += 1
          end
        end
      end
      return puts "You win!" if revealed_squares >= num_of_spaces    
    end
    
    for i in 0..8
      for j in 0..8
        if @b[[i, j]].bombed == true
          @b[[i, j]].revealed = 1
        end
      end
    end
    @b.render
    puts "You lost, you picked a mine"
  end
  
  def cursor(move)
    @b[@selector].selected = false
    if (@selector.first + move.first).between?(0,8)
      @selector[0] += move.first
    end
    if (@selector.last + move.last).between?(0,8)
      @selector[-1] += move.last
    end
    @b[@selector].selected = true
  end
  
  def selector_actions
    begin
      system("stty raw -echo")
      input = STDIN.getc.chr
    ensure
      system("stty -raw echo")
    end
    
    case input 
    when 'j'
      cursor([-1, 0])
    when 'i'
      cursor([0, -1])
    when 'k'
      cursor([0, 1])
    when 'l'
      cursor([1, 0])
    when 'r'
      return @b[@selector].reveal
    when 'f'
      return @b[@selector].flagged = ! @b[@selector].flagged
    when 's'
      save_file = @b.to_yaml
      f = File.open("save_file.txt", "w+") do |f|
        f.write(save_file)
        f.close
      end
      quit
    when 'o'
      contents = File.read("save_file.txt")
      saved_game = YAML::load(contents)
      @b = saved_game
    when 'q'
      quit
    else
      puts 'invalid entry'
      selector_actions
    end
  end
  
  def quit
    puts "You quit!"
    exit
  end

end

class Board
  def initialize(dim)
    y = -1
    @board = Array.new(dim) do
      y += 1
      x = -1
      Array.new(dim) do
        x += 1
        Tile.new(self, [x, y] )  
      end
    end
      
    return nil
  end
  
  def [](position)
  #  debugger
    @board[position.last][position.first]
  end
  
  def render
    system('clear')
    @board.each do |row|
      puts row.map(&:display).join("  ")
    end
    
    puts
    puts "Choose a selection, press \'r\' to reveal, \'f\' to flag, or \'s\' to save your file"
    puts "Or you can open a file by pressing \'o\' or \'q\' to quit"
    puts
    print ">"
  end
  
  def seed
    num_bombs = 10
    bombs_placed = 0
    until bombs_placed == num_bombs do
      sampled = @board.sample.sample
      unless sampled.bombed == true
        sampled.bombed = true
        bombs_placed += 1
      end
    end
    num_bombs
  end
end


class Tile
  attr_accessor :bombed, :flagged, :revealed, :selected
  attr_reader :position

  def initialize(board,position)
    @revealed = nil
    @board = board
    @position = position
    @selected = :selected
  end
  
  def inspect
    "<Tile position=#{position}>"
  end
  
  def display
    if self.selected == true
      return self.subdisplay.red
    else
      return self.subdisplay
    end
  end
  
  def subdisplay
    if (self.revealed != nil) && (self.bombed == true)
      return "☠".red
    elsif self.revealed != nil
      return "#{self.revealed}"
    elsif self.flagged == true
      return '⚑'
    end
    return "▢"
  end
  
  def reveal
    if @board[self.position].flagged == true
      return 'flag'
    elsif @board[self.position].bombed == true
      return nil
    else
      if self.neighbor_bomb_count > 0
        self.revealed = self.neighbor_bomb_count
      else
        self.revealed = 0
        self.neighbors.each do |el|
          if el.revealed == nil
            el.reveal
          end
        end
      end
    end
  end
  
  def neighbors
    neighbors = []
    for x in (-1..1)
      for y in (-1..1)
        x_neighbor = (@position.first + x)
        y_neighbor = (@position.last + y)
        unless @board[[x,y]] == self
          if x_neighbor.between?(0,8) && y_neighbor.between?(0,8)
            neighbors << @board[[x_neighbor, y_neighbor]]
          end
        end
      end  
    end
    neighbors
  end
  
  def neighbor_bomb_count
    bombs = 0
    self.neighbors.each do |neighbor|
      if neighbor.bombed == true
          bombs += 1
      end
    end
    bombs
  end
end

if __FILE__ == $PROGRAM_NAME
  g = Game.new
  g.run
end
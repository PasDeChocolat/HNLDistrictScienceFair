require 'matrix'

WIDTH = 600
HEIGHT = 600
NUM_BALLS = 10

def new_ball x, y, vx, vy
  Ball.new x, y, vx, vy, WIDTH, HEIGHT
end

class Ball
  def initialize(x, y, vx, vy, sketch_w, sketch_h)
    @pos = Vector[x, y]
    @vx, @vy = vx, vy
    @sketch_w, @sketch_h = sketch_w, sketch_h
  end
  
  def update(dvx, dvy)
    
  end

  def move
    @pos += Vector[@vx, @vy]

    @vx = -@vx.abs if x_pos >= @sketch_w
    @vx =  @vx.abs if x_pos <= 0
    @vy = -@vy.abs if y_pos >= @sketch_h
    @vy =  @vy.abs if y_pos <= 0
  end

  def display
    push_style
    push_matrix
    translate x_pos, y_pos

    # color_mode HSB, 100, 100, 100, 100
    # hue = map dx
    # fill
    ellipse 0, 0, 10, 10

    pop_matrix
    pop_style
  end

  private
    def x_pos
      @pos[0]
    end

    def y_pos
      @pos[1]
    end
end

def setup
  size WIDTH, HEIGHT

  @balls = []
  NUM_BALLS.times do
    @balls << new_ball(rand(width), rand(height), rand(20)-10, rand(20)-10)
  end
end

def draw
  background 0

  @balls.each do |ball|
    ball.move
    ball.display
  end
  # c = "rect 20, 20, 30, 30"
  # eval c
  # display_code c
end

def display_code c
  push_style
  # fill 0, 255, 0
  # text c, 30.0, 30.0, 100 
  pop_style
end
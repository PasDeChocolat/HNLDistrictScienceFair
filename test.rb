require 'matrix'

WIDTH = 600.0
HEIGHT = 600.0
NUM_BALLS = 40
MAX_COMP_V = 10.0
BALL_D = 20.0

def new_ball x, y, vx, vy
  Ball.new x, y, vx, vy, WIDTH, HEIGHT
end

class Ball
  @@max_v = Vector[MAX_COMP_V, MAX_COMP_V].magnitude

  def initialize(x, y, vx, vy, sketch_w, sketch_h)
    @pos = Vector[x, y]
    @vel = Vector[vx, vy]
    @sketch_w, @sketch_h = sketch_w, sketch_h
  end
  
  def update(dvx, dvy)
    
  end

  def move
    @pos += Vector[x_vel, y_vel]

    self.x_vel = -x_vel().abs if x_pos >= @sketch_w
    self.x_vel =  x_vel().abs if x_pos <= 0
    self.y_vel = -y_vel().abs if y_pos >= @sketch_h
    self.y_vel =  y_vel().abs if y_pos <= 0
  end

  def display
    push_style
    push_matrix
    translate x_pos, y_pos

    color_mode HSB, 360, 1, 1, 1
    hue = map(velocity, 0, @@max_v, 240, 360)
    fill hue, 1, 1, 1
    ellipse 0, 0, BALL_D, BALL_D

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

    def x_vel
      @vel[0]
    end

    def x_vel= vx
      @vel = Vector[vx, y_vel]
    end

    def y_vel
      @vel[1]
    end

    def y_vel= vy
      @vel = Vector[x_vel, vy]
    end

    def velocity
      @vel.magnitude
    end
end

def setup
  size WIDTH, HEIGHT

  @balls = []
  NUM_BALLS.times do
    @balls << new_ball( rand(width),
                        rand(height),
                        rand(MAX_COMP_V*2.0)-MAX_COMP_V,
                        rand(MAX_COMP_V*2.0)-MAX_COMP_V )
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
require 'matrix'

WIDTH = 600.0
HEIGHT = 600.0
NUM_BALLS = 40
MAX_COMP_V = 20.0
MIN_COMP_V = 0.1
BALL_D = 20.0

def new_ball x, y, vx, vy
  Ball.new x, y, vx, vy, WIDTH, HEIGHT
end

class Ball
  @@max_v = Vector[MAX_COMP_V, MAX_COMP_V].magnitude

  def initialize(x, y, vx, vy, sketch_w, sketch_h)
    @pos = Vector[x, y]
    @vel = Vector[vx, vy]
    @orig_vel = Vector[vx, vy]
    @sketch_w, @sketch_h = sketch_w, sketch_h
  end
  
  def constrain_velocity
    orig_x_vel_comp = @orig_vel[0].abs
    orig_y_vel_comp = @orig_vel[1].abs

    self.x_vel = [orig_x_vel_comp, x_vel].min
    self.y_vel = [orig_y_vel_comp, y_vel].min
    self.x_vel = [-orig_x_vel_comp, x_vel].max
    self.y_vel = [-orig_y_vel_comp, y_vel].max

    # Don't let the velocity get too close to 0.
    if (x_vel < MIN_COMP_V and x_vel > -MIN_COMP_V)
      is_neg_x_vel = x_vel < 0
      self.x_vel = MIN_COMP_V
      self.x_vel = x_vel * -1 if is_neg_x_vel
    end

    if (y_vel < MIN_COMP_V and y_vel > -MIN_COMP_V)
      is_neg_y_vel = y_vel < 0
      self.y_vel = MIN_COMP_V
      self.y_vel = y_vel * -1 if is_neg_y_vel
    end
  end

  def scale_velocity scale=1.0
    @vel = @vel * scale
    constrain_velocity
  end

  def move
    @pos += @vel

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

  line_idx = -1
  @balls.each_with_index do |ball, ball_idx|
    v_scale = map(mouse_x, 0, width, 0.9, 1.1).round(2)

    c = "ball.scale_velocity(#{v_scale})"
    eval c
    display_code(c, line_idx+=1) if ball_idx==0
    
    c = "ball.display"
    eval c
    display_code(c, line_idx+=1) if ball_idx==0

    ball.move
  end
end

def display_code c, line_idx
  y_origin = 30.0
  y = y_origin + line_idx*20
  push_style
  fill 0, 255, 0
  text c, 30.0, y, 100 
  pop_style
end
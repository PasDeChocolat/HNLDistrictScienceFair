load_library "pbox2d"
include_package 'pbox2d'
include_package 'org.jbox2d.collision.shapes'
include_package 'org.jbox2d.common'
include_package 'org.jbox2d.dynamics'
include_package 'org.jbox2d.dynamics.joints'
include_package 'org.jbox2d.dynamics.BodyDef'
include_package 'org.jbox2d.dynamics.contacts'
include_package 'org.jbox2d.collision.shapes'
include_package 'org.jbox2d.collision.shapes.Shape'

def setup
  size 400, 400

  # Initialize box2d physics and create the world
  @box2d = PBox2D.new(self)
  @box2d.createWorld()

  # Turn on collision listening!
  @box2d.listenForCollisions()

  # Make the box
  # @box = Box.new(width/2,height/2)
  @xoff = 0.0
  @yoff = 1000.0

  # Create the empty list
  @particles = []
end

def draw
  background(255)

  if (rand(10) < 2)
    sz = rand(8) - 4
    @particles << Particle.new(width/2,-20,sz, @box2d, height)
  end


  # We must always step through time!
  @box2d.step()

  # Make an x,y coordinate out of perlin noise
  x = noise(@xoff)*width
  y = noise(@yoff)*height
  @xoff += 0.01;
  @yoff += 0.01;

  # This is tempting but will not work!
  # box.body.setXForm(box2d.screenToWorld(x,y),0);

  # Instead update the spring which pulls the mouse along
  # if (mouse_pressed)
  #   @box.setLocation(mouse_x,mouse_y)
  # else
  #   @box.setLocation(x,y);
  # end

  # Look at all particles
  # for (int i = particles.size()-1; i >= 0; i--) {
  (0..(@particles.size-1)).to_a.reverse.each do |i|
    p = @particles[i]
    p.display()
    # Particles that leave the screen, we delete them
    # (note they have to be deleted from both the box2d world and our list
    if p.done()
      @particles.delete_at(i)
    end
  end

  # Draw the box
  # @box.display();

  # Draw the spring
  # spring.display();
end

class Particle
  include_package 'org.jbox2d.dynamics'

  # We need to keep track of a Body and a radius
  # Body body;
  # float r;
  # color col;

  def initialize x, y, r_, box2d_, sketch_height_ 
    @r = r_
    @box2d = box2d_
    @sketch_height = sketch_height_
    # This function puts the particle in the Box2d world
    @body = makeBody(x, y, @r)
    @body.setUserData(self)
    @col = color(175)
  end

  # This function removes the particle from the box2d world
  def killBody
    @box2d.destroyBody(@body)
  end

  # Change color when hit
  def change()
    @col = color(255, 0, 0)
  end

  # Is the particle ready for deletion?
  def done()
    # Let's find the screen position of the particle
    pos = @box2d.getBodyPixelCoord(@body)
    # Is it off the bottom of the screen?
    if (pos.y > @sketch_height+@r*2)
      puts "HEIGHT: #{@sketch_height}"
      killBody()
      return true
    end
    return false
  end

  def display()
    # We look at each body and get its screen position
    pos = @box2d.getBodyPixelCoord(@body)
    # Get its angle of rotation
    a = @body.getAngle()
    push_matrix()
    translate(pos.x, pos.y)
    rotate(a)
    fill(@col)
    stroke(0)
    stroke_weight(1)
    ellipse(0, 0, @r*2, @r*2)
    # Let's add a line so we can see the rotation
    line(0, 0, @r, 0)
    pop_matrix()
  end

  # Here's our function that adds the particle to the Box2D world
  def makeBody(x, y, r)
    # Define a body
    bd = org.jbox2d.dynamics.BodyDef.new()
    # Set its position
    bd.position = @box2d.coordPixelsToWorld(x, y);
    bd.type = org.jbox2d.dynamics.BodyType::DYNAMIC
    
    body = @box2d.createBody(bd)

    # Make the body's shape a circle
    cs = org.jbox2d.collision.shapes.CircleShape.new()
    cs.m_radius = @box2d.scalarPixelsToWorld(r)

    fd = FixtureDef.new()
    fd.shape = cs
    # Parameters that affect physics
    fd.density = 1;
    fd.friction = 0.01;
    fd.restitution = 0.3;

    # Attach fixture to body
    body.createFixture(fd)

    body.setAngularVelocity(rand(20) - 10)
    return body
  end
end
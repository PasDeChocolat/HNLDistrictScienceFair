load_library "SimpleOpenNI"
include_package 'SimpleOpenNI'

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
  size 1024,768,P3D
  background 0

  setup_kinect
  setup_box2d

  stroke(255,255,255)
  smooth()
end

def draw
  # update the cam
  @context.update()

  background 0
  # display_code "hello"

  # set the scene pos
  translate(width/2, height/2, 0);
  rotate_x(@rotX)
  rotate_y(@rotY)
  scale(@zoomF)

  depthMap = @context.depthMap()
  userMap = @context.userMap()
  steps   = 3  # to speed up the drawing, draw every third point
  # index
  # realWorldPoint

  translate(0,0,-1000)  # set the rotation center of the scene 1000 infront of the camera

  # draw the skeleton if it's available
  userList = @context.getUsers()
  com = PVector.new(1, 1, 1)
  # for(int i=0;i<userList.length;i++)
  (0...userList.size).each do |i|
    @context.startTrackingSkeleton(userList[i]);
    if (@context.isTrackingSkeleton(userList[i]))
      draw_skeleton(userList[i])
    end
    
    # draw the center of mass with a plus sign.
    if(@context.getCoM(userList[i],com))
      stroke(100,255,0)
      stroke_weight(1)
      begin_shape(LINES)
        vertex(com.x - 15,com.y,com.z)
        vertex(com.x + 15,com.y,com.z)
        
        vertex(com.x,com.y - 15,com.z)
        vertex(com.x,com.y + 15,com.z)

        vertex(com.x,com.y,com.z - 15)
        vertex(com.x,com.y, com.z + 15)
      end_shape()
    end
  end

  @context.drawCamFrustum()

  userList.each do |u|
    display_ball_for_user(u)
  end

  display_box2d

  before_rotation = false
  display_code "hello", before_rotation
end

def setup_kinect
  @context = SimpleOpenNI.new(self)
  @zoomF =0.5
  @rotX = radians(180)  # by default rotate the hole scene 180deg around the x-axis, 
                        # the data from openni comes upside down
  @rotY = radians(0)

  if !@context.isInit
     puts "Can't init SimpleOpenNI, maybe the camera is not connected!"
     exit
  end

  @user_positions = []

  # disable mirror
  @context.setMirror(false)

  # enable depthMap generation 
  @context.enableDepth()

  # enable skeleton generation for all joints
  @context.enableUser()
end

def setup_box2d
  # Initialize box2d physics and create the world
  @box2d = PBox2D.new(self)
  @box2d.createWorld()

  # Make the box
  @boxes = []
  # @boxes << Box.new(0,0, 50.0, @box2d)

  @xoff = 0.0
  @yoff = 1000.0

  # Create the empty list
  @particles = []
end

def display_box2d
  # x 500
  # y 200
  # x_offset = map(mouse_x, 0, width, -1000, 1000)
  # y_offset = map(mouse_y, 0, height, -1000, 1000)
  # puts "xoff: #{x_offset}, yoff: #{y_offset}"
  x_offset = 500
  y_offset = 200
  # spread = map(mouse_x, 0, width, 0, 2*width)
  spread = width - 250

  if (rand(100) < 90)
    5.times do
      sz = rand(8) - 4
      # rain_x = width/2.0
      rain_x = rand(spread) - x_offset
      rain_y = y_offset
      @particles << Particle.new(rain_x, rain_y, sz.to_f, @box2d, height)
    end
  end


  # We must always step through time!
  # @box2d.step()
  @box2d.step(1/60.0, 8, 3)
  @box2d.setGravity(0, 9.8) # must reverse gravity due to Kinect rotational transform

  # @boxes.each_with_index do |box, index|
  #   x = noise(@xoff, index)*width
  #   y = noise(@yoff, index)*height
  #   box.setLocation(x,y)
  # end
  @xoff += 0.01;
  @yoff += 0.01;

  # Look at all particles
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
  # @boxes.each do |box|
  #   box.display()
  # end
end

def display_code code, before_rotation=true
  push_style
  push_matrix

  fill(0,255,0)
  # z = map(mouse_x, 0, width, -3000, 3000)
  if before_rotation
    textSize(60)
    z = -100 # before scene rotation
  else
    textSize(20)
    z = -164 # after scene rotation

    rotate_x(-@rotX)
    translate(-width/3.0, -height/3.0, 0);
  end
  text(code, 0, 0, z)

  pop_matrix
  pop_style
end

def display_ball_for_user(user_id)
  user_pos = @user_positions.find { |u| u[:user_id] == user_id }
  return if   user_pos.nil?

  head_pos       = user_pos[:head]
  right_hand_pos = user_pos[:right_hand]
  left_hand_pos  = user_pos[:left_hand]
  r = right_hand_pos.dist(left_hand_pos)/2.0

  push_style
  push_matrix
  stroke 120
  fill 0, 255, 255
  # translate head_pos.x, head_pos.y-r, head_pos.z
  # sphere r
  box_index = user_id-1
  box = @boxes[box_index]
  push_matrix
  previous_width = 20
  if box
    previous_width = box.w
    box.killBody
  end

  # move box
  x = map(head_pos.x, -1200, 1200, -100, 100)
  y = map(head_pos.y, -1200, 1200, -100, 100)

  hand_dist = map(r*2.0, 0, width, 20, 100)
  box_w = lerp(previous_width, hand_dist, 0.1)
  box = Box.new(x, y, box_w, @box2d)
  if box_index < @boxes.size
    @boxes[box_index] = box
  else
    @boxes << box
  end
  box.display
  pop_matrix

  pop_matrix
  pop_style
end

# draw the skeleton with the selected joints
def draw_skeleton(userId)
  stroke_weight(3)

  # to get the 3d joint data
  drawLimb(userId, SimpleOpenNI::SKEL_HEAD, SimpleOpenNI::SKEL_NECK);

  drawLimb(userId, SimpleOpenNI::SKEL_NECK, SimpleOpenNI::SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI::SKEL_LEFT_SHOULDER, SimpleOpenNI::SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI::SKEL_LEFT_ELBOW, SimpleOpenNI::SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI::SKEL_NECK, SimpleOpenNI::SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI::SKEL_RIGHT_SHOULDER, SimpleOpenNI::SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI::SKEL_RIGHT_ELBOW, SimpleOpenNI::SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI::SKEL_LEFT_SHOULDER, SimpleOpenNI::SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI::SKEL_RIGHT_SHOULDER, SimpleOpenNI::SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI::SKEL_TORSO, SimpleOpenNI::SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI::SKEL_LEFT_HIP, SimpleOpenNI::SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI::SKEL_LEFT_KNEE, SimpleOpenNI::SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI::SKEL_TORSO, SimpleOpenNI::SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI::SKEL_RIGHT_HIP, SimpleOpenNI::SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI::SKEL_RIGHT_KNEE, SimpleOpenNI::SKEL_RIGHT_FOOT);  

  # draw body direction
  bodyDir = PVector.new(0,0,0)
  bodyCenter = PVector.new(0,0,0)
  # getBodyDirection(userId,bodyCenter,bodyDir)
  
  bodyDir.mult(200);  # 200mm length
  bodyDir.add(bodyCenter);
  
  stroke(255,200,200);
  line(bodyCenter.x,bodyCenter.y,bodyCenter.z,
       bodyDir.x ,bodyDir.y,bodyDir.z);

  stroke_weight(1)
 
end

def drawLimb(userId,jointType1,jointType2)
  jointPos1 = PVector.new(0,0,0)
  jointPos2 = PVector.new(0,0,0)

  # draw the joint position
  confidence = @context.getJointPositionSkeleton(userId,jointType1,jointPos1)
  confidence = @context.getJointPositionSkeleton(userId,jointType2,jointPos2)

  default_pos_info = {user_id: userId}
  if (SimpleOpenNI::SKEL_HEAD == jointType1)
    head_position = @user_positions.find { |u| u[:user_id] == userId }
    if head_position.nil?
      head_position = default_pos_info
      @user_positions << head_position
    end
    head_position[:head] = jointPos1
  end

  if ([SimpleOpenNI::SKEL_RIGHT_HAND, SimpleOpenNI::SKEL_LEFT_HAND].include? jointType2)
    hand_positions = @user_positions.find { |u| u[:user_id] == userId }
    if hand_positions.nil?
      hand_positions = default_pos_info
      @user_positions << hand_positions
    end
    if (jointType2 == SimpleOpenNI::SKEL_RIGHT_HAND)
      hand_positions[:right_hand] = jointPos2
    elsif (jointType2 == SimpleOpenNI::SKEL_LEFT_HAND)
      hand_positions[:left_hand] = jointPos2
    end
  end

  # stroke(255,0,0,confidence * 200 + 55)
  stroke(255,0,0,confidence*55 + 200)
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z)
  # puts "x: #{jointPos1.x}, y: #{jointPos1.y}, z: #{jointPos1.z}"
end

class Particle
  include_package 'org.jbox2d.dynamics'
  include_package 'org.jbox2d.collision.shapes'

  # We need to keep track of a Body and a radius
  # Body body;
  # float r;
  # color col;

  def initialize x, y, r_, box2d_, sketch_height_ 
    x, y = x.to_f, y.to_f
    @r = r_.to_f
    @box2d = box2d_
    @sketch_height = sketch_height_.to_f
    # This function puts the particle in the Box2d world
    @body = makeBody(x, y, @r)  
    @body.setUserData(self)
    @col = color(76, 124, 216)
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
    no_stroke
    ellipse(0, 0, @r*2, @r*2)
    # Let's add a line so we can see the rotation
    stroke(0)
    stroke_weight(1)
    line(0, 0, @r, 0)
    pop_matrix()
  end

  # Here's our function that adds the particle to the Box2D world
  def makeBody(x, y, r)
    x, y = x.to_f, y.to_f
    r = r.to_f

    # Define a body
    bd = BodyDef.new()
    # Set its position
    bd.position = @box2d.coordPixelsToWorld(x, y);
    bd.type = BodyType::DYNAMIC
    
    body = @box2d.createBody(bd)

    # Make the body's shape a circle
    cs = CircleShape.new()
    cs.m_radius = @box2d.scalarPixelsToWorld(r)

    fd = FixtureDef.new()
    fd.shape = cs
    # Parameters that affect physics
    fd.density = 1.0;
    fd.friction = 0.01;
    fd.restitution = 0.3;

    # Attach fixture to body
    body.createFixture(fd)

    body.setAngularVelocity(rand(20) - 10)
    return body
  end
end

class Box
  include_package 'org.jbox2d.dynamics'
  include_package 'org.jbox2d.common'
  include_package 'org.jbox2d.collision.shapes'

  attr_reader :w, :h
  # We need to keep track of a Body and a width and height
  # Body body;
  # float w;
  # float h;
  
  # boolean dragged = false;

  # Constructor
  def initialize x_, y_, w_, box2d_
    @box2d = box2d_
    @dragged = false
    @w = w_
    @h = w_
    x, y = x_.to_f, y_.to_f
    # Add the box to the box2d world
    @body = makeBody(Vec2.new(x,y),@w,@h)
    @body.setUserData(self)
  end

  # This function removes the particle from the box2d world
  def killBody()
    @box2d.destroyBody(@body);
  end

  def contains(x, y)
    x, y = x.to_f, y.to_f
    worldPoint = @box2d.coordPixelsToWorld(x, y)
    f = @body.getFixtureList()
    return f.testPoint(worldPoint)
  end
  
  def setAngularVelocity(a)
    a = a.to_f
    @body.setAngularVelocity(a)
  end
  def setVelocity(v)
    @body.setLinearVelocity(v)
  end
  
  def setLocation(x, y)
    x, y = x.to_f, y.to_f
    pos = @body.getWorldCenter()
    target = @box2d.coordPixelsToWorld(x,y)
    diff = Vec2.new(target.x-pos.x,target.y-pos.y)
    diff.mulLocal(50)
    setVelocity(diff)
    setAngularVelocity(0)
  end

  # Drawing the box
  def display()
    # We look at each body and get its screen position
    pos = @box2d.getBodyPixelCoord(@body)
    # Get its angle of rotation
    a = @body.getAngle()

    rect_mode(PConstants::CENTER)
    push_matrix
    translate(pos.x,pos.y)
    rotate(a)
    fill(175)
    stroke(0)
    rect(0,0,@w,@h)
    pop_matrix
  end


  # This function adds the rectangle to the box2d world
  def makeBody(center, w_, h_)
    w_, h_ = w_.to_f, h_.to_f

    # Define and create the body
    bd = BodyDef.new()
    bd.type = BodyType::KINEMATIC
    bd.position.set(@box2d.coordPixelsToWorld(center))
    bd.fixedRotation = true
    body = @box2d.createBody(bd)

    # Define a polygon (this is what we use for a rectangle)
    ps = PolygonShape.new()
    box2dW = @box2d.scalarPixelsToWorld(w_/2.0)
    box2dH = @box2d.scalarPixelsToWorld(h_/2.0)
    ps.setAsBox(box2dW, box2dH)

    # Define a fixture
    fd = FixtureDef.new()
    fd.shape = ps
    # Parameters that affect physics
    fd.density = 1.0
    fd.friction = 0.3
    fd.restitution = 0.5

    body.createFixture(fd)
    return body
  end
end

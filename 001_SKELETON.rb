load_library "SimpleOpenNI"
include_package 'SimpleOpenNI'
# include_package 'org.openkinect'
# include_package 'org.openkinect.processing'

def setup
  size 1024,768,P3D
  background 0

  @context = SimpleOpenNI.new(self)
  @zoomF =0.5
  @rotX = radians(180)  # by default rotate the hole scene 180deg around the x-axis, 
                        # the data from openni comes upside down
  @rotY = radians(0)

  if !@context.isInit
     puts "Can't init SimpleOpenNI, maybe the camera is not connected!"
     exit
  end

  # disable mirror
  @context.setMirror(false)

  # enable depthMap generation 
  @context.enableDepth()

  # enable skeleton generation for all joints
  @context.enableUser()

  stroke(255,255,255)
  smooth()
end

def draw
  # update the cam
  @context.update()

  background 0

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
      
      fill(0,255,100)
      text(userList[i].to_s,com.x,com.y,com.z)
    end
  end

  @context.drawCamFrustum()
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
  getBodyDirection(userId,bodyCenter,bodyDir)
  
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

  stroke(255,0,0,confidence * 200 + 55)
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z)
  
  # drawJointOrientation(userId,jointType1,jointPos1,50);
end

def getBodyDirection *stuff

end

# def onNewUser(curContext,userId)
#   puts("onNewUser - userId: " + userId);
#   puts("\tstart tracking skeleton");
  
#   @context.startTrackingSkeleton(userId);
# end
$ ->
  canvas = setCanvasSize()
  gl = canvas.getContext('webgl2')
  gl.enable(gl.DEPTH_TEST)
  gl.enable(gl.CULL_FACE)
  gl.clearColor(0.1,0.0,0.5,1.0)
  RADIUS = 6370000

  program = new ShaderProgram(gl)

  program.addShader(gl.VERTEX_SHADER,'''
    #version 300 es
    #define M_PI 3.1415926535897932384626433832795
    in highp vec4 a_Position;
    in vec3 a_Bary;
    in float a_Triangle;
    out vec3 v_Bary;
    flat out int v_Triangle;
    flat out int v_InstanceId;
    flat out int v_subpatch;
    uniform mediump mat4 u_ModelMatrix;
    uniform mediump mat4 u_ViewMatrix;
    uniform mediump mat4 u_ProjMatrix;
    uniform float subpatch;
    uniform mediump mat4 u_PatchMatrix;

    mat4 oMat[8] = mat4[](
      //    0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
      mat4( 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),      // 0
      mat4( 0, 0, 1, 0, 0, 1, 0, 0,-1, 0, 0, 0, 0, 0, 0, 1),      // 1
      mat4(-1, 0, 0, 0, 0, 1, 0, 0, 0, 0,-1, 0, 0, 0, 0, 1),      // 2
      mat4( 0, 0,-1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1),      // 3
      mat4(-1, 0, 0, 0, 0,-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1),      // 4
      mat4( 0, 0,-1, 0, 0,-1, 0, 0,-1, 0, 0, 0, 0, 0, 0, 1),      // 5
      mat4( 1, 0, 0, 0, 0,-1, 0, 0, 0, 0,-1, 0, 0, 0, 0, 1),      // 6
      mat4( 0, 0, 1, 0, 0,-1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1));     // 7

    void main() {

      //if (gl_InstanceID == u_patches[0].w) {

      //}

      vec4 pos = a_Position;
      
      if (gl_InstanceID < 8 && subpatch == -1.0) {
        pos = vec4(normalize(a_Position.xyz),1.0);
        pos = vec4(pos.xyz*float(''' + RADIUS.toString() + '''),1.0);
        pos = oMat[gl_InstanceID] * pos;
      } else {
        pos = u_PatchMatrix * pos;
        pos = vec4(normalize(pos.xyz),1.0);
        pos = vec4(pos.xyz*float(''' + RADIUS.toString() + '''),1.0);
        

      }
      pos = u_ProjMatrix * u_ViewMatrix * u_ModelMatrix * pos;
      gl_Position = pos;
      v_Bary = a_Bary;
      v_Triangle = int(a_Triangle);
      v_InstanceId = gl_InstanceID;
      v_subpatch = int(subpatch);
    }
  ''')

  program.addShader(gl.FRAGMENT_SHADER,'''
    #version 300 es
    #define M_PI 3.1415926535897932384626433832795
    precision mediump float;
    in vec3 v_Bary;
    flat in int v_Triangle;
    flat in int v_InstanceId;
    flat in int v_subpatch;
    out vec4 fragcolor;
    uniform mediump vec2 u_discardPile[50];

    vec3 colors[8] = vec3[](
        vec3(1.0,1.0,1.0),   // 0 - white
        vec3(1.0,1.0,0.0),   // 1 - yellow
        vec3(1.0,0.0,1.0),   // 2 - purple
        vec3(1.0,0.0,0.0),   // 3 - red
        vec3(0.0,1.0,1.0),   // 4 - teal
        vec3(0.0,1.0,0.0),   // 5 - green
        vec3(0.0,0.0,1.0),   // 6 - blue
        vec3(0.2,0.2,0.2));  // 7 - gray

    float edgeFactor(){
      vec3 d = fwidth(v_Bary);
      vec3 a3 = smoothstep(vec3(0.0), 1.25*d, v_Bary);
      return min(min(a3.x, a3.y), a3.z);
    }

    void main() {
      if (int(u_discardPile[0].x) == v_InstanceId && int(u_discardPile[0].y) == v_Triangle && v_subpatch == -1) discard;
      vec3 faceColor = colors[v_InstanceId];
      vec3 wireColor = vec3(0, 0, 0);
      fragcolor = vec4(mix(wireColor, faceColor, edgeFactor()),1);
    }
  ''')

  diffX = 0
  diffY = 0
  dragging = false
  x = 0
  y = 0
  rX = 0
  rY = 0
  z = RADIUS * 2

  program.activate()

  setSize = ->
    gl.viewport(0, 0, canvas.width, canvas.height)
    proj = Matrix.perspective(90, canvas.width / canvas.height, z-RADIUS, z+RADIUS)
    program.setUniformMatrix('u_ProjMatrix', proj.array())

  setSize()

  $(window).resize(->
    setCanvasSize()
    setSize()
  )

  v0 = new Vector([0, 1, 0])
  v1 = new Vector([0, 0, 1])
  v2 = new Vector([1, 0, 0])
  octahedron = new Model(gl,program,new Face(v0,v1,v2).tessellate(3))

  subPatch = new Model(gl,program,new Face(v0,v1,v2).tessellate(3))
  d = octahedron.faces[19].v[0].minus(v0)

  patchMatrix = Matrix.scalation(1/8,1/8,1/8)
    .translate(d.a[0]+v0.a[0]*(7/8),d.a[1]+v0.a[1]*(7/8),d.a[2]+v0.a[2]*(7/8))
  program.setUniformVectorArray('u_discardPile',[0,19],2)

  diffX = 0
  diffY = 0
  dragging = false
  x = 0
  y = 0
  rX = 0
  rY = 0
  z = RADIUS * 2

  $(document.body).append('<div id="overlay"></div>')
  $('#overlay').css({ position:'fixed', color:'white', left:10 + 'px', top:10 + 'px' })

  octahedron.animate = (elapsed) ->
    rX += if dragging? and dragging then diffX else 0
    rY += if dragging? and dragging then diffY else 0
    model = Matrix.rotation(-rX * 0.4 % 360, 0,1,0).multiply(
      Matrix.rotation(-rY * 0.4 % 360, 1,0,0))
    program.setUniformMatrix('u_ModelMatrix', model.array())
    view = Matrix.lookAt([0, 0, z],[0,0,0],[0,1,0])
    program.setUniformMatrix('u_ViewMatrix', view.array())
    proj = Matrix.perspective(90, canvas.width / canvas.height, z-RADIUS, z+RADIUS)
    program.setUniformMatrix('u_ProjMatrix', proj.array())
    pvm = proj.multiply(view).multiply(model)
  
  octahedron.draw = -> 
    octahedron.activate()
    program.setUniform('subpatch',-1)
    gl.drawArraysInstanced(gl.TRIANGLES, 0, octahedron.vertexCount(), 8)
    
    subPatch.activate()
    program.setUniform('subpatch',0)
    program.setUniformMatrix('u_PatchMatrix',patchMatrix.array())
    gl.drawArraysInstanced(gl.TRIANGLES, 0, subPatch.vertexCount(), 1)

  engine = new Engine(gl)
  engine.addModel(octahedron)
  engine.start()

  $("#gl").mousedown((e) ->
    x = e.pageX
    y = e.pageY
    dragging = true
  )

  $("#gl").mousemove((e) ->
    diffX = if x? then x - e.pageX else 0
    diffY = if y? then y - e.pageY else 0
    x = e.pageX
    y = e.pageY
  )

  $("#gl").mouseup (e)-> dragging = false
  $('#gl').mousewheel (e) ->
    toSurface = z-RADIUS
    z = Math.max(RADIUS+2,z + toSurface * e.deltaY * 0.01)
    $('#overlay').text("z: #{z.toFixed(2)}, deltaY: #{e.deltaY}, to surface: #{(z-RADIUS).toFixed(2)}")
    
setCanvasSize = ->
  canvas = document.getElementById('gl')
  devicePixelRatio = window.devicePixelRatio || 1
  overdraw = 1
  scale = devicePixelRatio * overdraw
  canvas.width  = window.innerWidth  * scale
  canvas.height = window.innerHeight * scale
  canvas.style.width  = window.innerWidth  + "px"
  canvas.style.height = window.innerHeight + "px"
  canvas
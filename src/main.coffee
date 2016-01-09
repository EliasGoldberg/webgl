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
    uniform mediump mat4 u_ModelMatrix;
    uniform mediump mat4 u_ViewMatrix;
    uniform mediump mat4 u_ProjMatrix;
    uniform mediump mat4 u_PatchMatrix[128];
    uniform mediump vec2 u_discardPile[128];
    uniform mediump float u_discardCount;

    void main() {
      vec4 pos = a_Position;
      
      pos = u_PatchMatrix[gl_InstanceID] * pos;
      pos = vec4(normalize(pos.xyz),1.0);
      pos = vec4(pos.xyz*float(''' + RADIUS.toString() + '''),1.0);
      
      pos = u_ProjMatrix * u_ViewMatrix * u_ModelMatrix * pos;
      gl_Position = pos;
      v_Bary = a_Bary;
      v_Triangle = int(a_Triangle);
      v_InstanceId = gl_InstanceID;
    }
  ''')

  program.addShader(gl.FRAGMENT_SHADER,'''
    #version 300 es
    #define M_PI 3.1415926535897932384626433832795
    precision mediump float;
    in vec3 v_Bary;
    flat in int v_Triangle;
    flat in int v_InstanceId;
    out vec4 fragcolor;
    uniform mediump vec2 u_discardPile[128];
    uniform mediump float u_discardCount;

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
      for (int i = 0; i<int(u_discardCount);++i) {
        if (int(u_discardPile[i].x) == v_InstanceId && int(u_discardPile[i].y) == v_Triangle) discard;
      }
      
      vec3 faceColor;
      //if (v_InstanceId < 8)
      //  faceColor = colors[v_InstanceId];
      //else
        faceColor = vec3(1.0,0.5,0.0);

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
    proj = Matrix.perspective(45, canvas.width / canvas.height, z-RADIUS-1, z+RADIUS+500)
    program.setUniformMatrix('u_ProjMatrix', proj.array())

  setSize()

  $(window).resize(->
    setCanvasSize()
    setSize()
  )

  v0 = new Vector([0, 1, 0])
  v1 = new Vector([0, 0, 1])
  v2 = new Vector([1, 0, 0])
  tess = 4
  scaler = 1/Math.pow(2,tess)
  rawFace = new Face(v0,v1,v2)
  octahedron = new Model(gl,program,rawFace.tessellate(tess))
  
  ###
  discards = [ 0,0,  1,1,  2,2,  3,3,  4,4,  5,5,  6,6,  7,7, 
               0,8,  1,9, 2,10, 3,11, 4,12, 5,13, 6,14, 7,15,
              0,16, 1,17, 2,18, 3,19, 4,20, 5,21, 6,22, 7,23,
              0,24, 1,25, 2,26, 3,27, 4,28, 5,29, 6,30, 7,31,
              0,32, 1,33, 2,34, 3,35, 4,36, 5,37, 6,38, 7,39,
              0,40, 1,41, 2,42, 3,43, 4,44, 5,45, 6,46, 7,47,
              0,48, 1,49, 2,50, 3,51, 4,52, 5,53, 6,54, 7,55,
              0,56, 1,57, 2,58, 3,59, 4,60, 5,61, 6,62, 7,63, 8,0, 8+64,0]
  ###
  discards = []
  patchArray = []
  patchMatrices = []
  octantTransforms = [
    Matrix.identity(), Matrix.rotation(90,0,1,0), 
    Matrix.rotation(180,0,1,0), Matrix.rotation(270,0,1,0),
    Matrix.scalation(-1,-1,1), Matrix.scalation(-1,-1,1).rotate(90,0,1,0),
    Matrix.scalation(-1,-1,1).rotate(180,0,1,0), Matrix.scalation(-1,-1,1).rotate(270,0,1,0)
  ]
  octantArrays = []
  for transformation in octantTransforms
    octantArrays = octantArrays.concat(transformation.m) 

  tessellate = ->
    patchArray = [].concat(octantArrays)
    patchMatrices = [].concat(octantTransforms)

    for idx in [0..discards.length-1] by 2
      discardOctant = discards[idx]
      discardFace = discards[idx+1]
      
      centerFlip = octahedron.faces[discardFace].isUpsidedown * 180
      axis = octahedron.faces[discardFace].getNormal()

      patchMatrix = Matrix.identity() 
      nested = true
      while nested
        d = octahedron.faces[discardFace].centroid.minus(octahedron.faces[0].centroid)
        patchMatrix = patchMatrix.multiply(
          Matrix.scalation(scaler,scaler,scaler)
          .translate(d.a[0],d.a[1],d.a[2])
          .translate(v0.a[0]*(1-scaler),v0.a[1]*(1-scaler),v0.a[2]*(1-scaler))
        )
        if discardOctant >= 8
          discardOctant = discards[(discardOctant-8)*2]
        else
          nested = false

      patchMatrix = octantTransforms[discardOctant]
        .multiply(patchMatrix)
        .multiply(Matrix.rotation(centerFlip,axis.a[0],axis.a[1],axis.a[2]))
      patchArray = patchArray.concat(patchMatrix.m)
      patchMatrices.push(patchMatrix)

    program.setUniformVectorArray('u_discardPile',discards,2)
    program.setUniform('u_discardCount',discards.length / 2)
    program.setUniformMatrix('u_PatchMatrix',patchArray)

  diffX = 0
  diffY = 0
  dragging = false
  x = 0
  y = 0
  rX = 0
  rY = 0
  z = RADIUS * 4

  $(document.body).append('<div id="overlay"></div>')
  $('#overlay').css({ position:'fixed', backgroundColor:'black', color:'white', left:10 + 'px', top:10 + 'px' })

  $(document.body).append('<div id="lower-left"></div>')
  $('#lower-left').css({ position:'fixed', backgroundColor:'black', color:'white', left:10 + 'px', bottom:10 + 'px' })

  frame = 0
  metrics = {trans: 0, normalAngle: 0}
  octahedron.animate = (elapsed) ->
    rX += if dragging? and dragging then diffX else 0
    rY += if dragging? and dragging then diffY else 0
    model = Matrix.rotation(-rX * 0.4 % 360, 0,1,0).multiply(
      Matrix.rotation(-rY * 0.4 % 360, 1,0,0))
    program.setUniformMatrix('u_ModelMatrix', model.array())
    view = Matrix.lookAt([0, 0, z],[0,0,0],[0,1,0])
    program.setUniformMatrix('u_ViewMatrix', view.array())
    proj = Matrix.perspective(45, canvas.width / canvas.height, z-RADIUS-1, z+RADIUS+500)
    program.setUniformMatrix('u_ProjMatrix', proj.array())

    tessellate()
    possiblePatches = []

    for matrix,i in patchMatrices
      possiblePatches = possiblePatches.concat(rawFace.getPossiblePatches(new Vector([0,0,z]),matrix,model,i,metrics))
    possiblePatches.sort((a,b) -> a.score - b.score)
    discards = []
    for possiblePatch,i in possiblePatches[0..127]
      discards.push(possiblePatch.parentInstance)
      discards.push(possiblePatch.id)
    tessellate()
    frame += 1
    if (frame % 60 is 0)
      $('#lower-left').text("#{possiblePatches.length} #{(metrics.trans/60).toFixed(0)} #{(metrics.normalAngle/60).toFixed(0)}")
      metrics = {trans: 0, normalAngle: 0}


  
  octahedron.draw = -> 
    octahedron.activate()
    gl.drawArraysInstanced(gl.TRIANGLES, 0, octahedron.vertexCount(), 8 + (discards.length / 2))

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
    #$('#overlay').text("z: #{z.toFixed(2)}, deltaY: #{e.deltaY}, to surface: #{(z-RADIUS).toFixed(2)}")
    
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
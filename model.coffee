class @Model

  constructor: (@gl,@program) ->
    @vertexToIndexMap = {}
    @faceToIndexLocationMap = {}
    @vertexReferenceCounts = {}
    @bufferByteCounts = {}

    @vertices = []
    @indices = []

    @stride = 6
    @pointers = [{name: 'a_Position', dim: 3, offset: 0}
                {name: 'a_Bary', dim: 3, offset: 3}]
    @uniforms = []
    @textures = []

    @program.setUniform(u.name, u.value) for u in @uniforms
    this.setupTexture(t.url, t.sampler, i) for t,i in @textures

  addFaces: (faces) ->
    for face in faces
      @faceToIndexLocationMap[face.toString()] = @indices.length
      for i in [0..2]
        vertex = face.v[i]
        if not this.vertexExists(vertex)
          bary = this.getBary(face,i)
          face.setBary(bary,i)
          @vertices = @vertices.concat(vertex.elements()).concat(bary)
          @vertexReferenceCounts[vertex.toString()] = 1
        else
          @vertexReferenceCounts[vertex.toString()]++
          bary = this.getBary(face,i)
          face.setBary(bary,i)
        this.addIndex(vertex)
    this.buildModel()

  addIndex: (v) ->
    isNew = not this.vertexExists(v)
    if isNew then @vertexToIndexMap[v.toString()] = @vertices.length / @stride - 1
    index = @vertexToIndexMap[v.toString()]
    @indices.push(index)

  removeFaces: (faces) ->
    for face in faces
      for vertex in face.v
        @vertexReferenceCounts[vertex.toString()]--
        if @vertexReferenceCounts[vertex.toString()] is 0
          index = @vertexToIndexMap[vertex.toString()]
          @vertices.splice(index*@stride,@stride)
          delete @vertexToIndexMap[vertex.toString()]
          for laterIndex,i in @indices when laterIndex > index then @indices[i]--
          for v,laterIndex of @vertexToIndexMap when laterIndex  > index
            @vertexToIndexMap[v]--

      location = @faceToIndexLocationMap[face.toString()]
      @indices.splice(location, 3)
      delete @faceToIndexLocationMap[face.toString()]
      for otherFace,otherLocation of @faceToIndexLocationMap when otherLocation > location
        @faceToIndexLocationMap[otherFace] = otherLocation - 3

    this.buildModel()

  vertexExists: (v) -> @vertexToIndexMap[v.toString()]?

  getBary: (face,i) ->
    if face.b[i]? then return face.b[i]
    existingBarys = (this.getExistingBary(v) for v,j in face.v when j != i and this.vertexExists(v))
    switch
      when existingBarys.length is 2 then Face.uniqueBary(existingBarys[0], existingBarys[1])
      when existingBarys.length < 2 and i is 0 then [1,0,0]
      when existingBarys.length < 2 and i is 1 then [0,1,0]
      when existingBarys.length < 2 and i is 2 then [0,0,1]

  getExistingBary: (v) ->
    i = @vertexToIndexMap[v.toString()]*@stride+3
    @vertices[i..i+2]

  buildModel: ->
    @arrayBuffer = this.makeArrayBuffer(@vertices)
    s = @bufferByteCounts[@arrayBuffer]
    @program.setAttribPointer(@arrayBuffer, p.name, p.dim, @stride*s, p.offset*s) for p in @pointers
    @indexBuffer = this.makeIndexBuffer(@indices)

  makeArrayBuffer: (bufferData) ->
    if !@arrayBuffer? then @arrayBuffer = @gl.createBuffer()
    floatArray = new Float32Array(bufferData)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @arrayBuffer);
    @gl.bufferData(@gl.ARRAY_BUFFER, floatArray, @gl.STATIC_DRAW)
    @bufferByteCounts[@arrayBuffer] = floatArray.BYTES_PER_ELEMENT
    @arrayBuffer

  makeIndexBuffer: (bufferData) ->
    if !@indexBuffer? then @indexBuffer = @gl.createBuffer()
    uIntArray = new Uint8Array(bufferData)
    @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, @indexBuffer)
    @gl.bufferData(@gl.ELEMENT_ARRAY_BUFFER, uIntArray, @gl.STATIC_DRAW)
    @bufferByteCounts[@indexBuffer] = uIntArray.BYTES_PER_ELEMENT
    @indexBuffer

  setupTexture: (url,sampler,i) ->
    img = new Image()
    img.onload = =>
      texture = @gl.createTexture()
      @gl.pixelStorei(@gl.UNPACK_FLIP_Y_WEBGL,1)
      @gl.activeTexture(@gl["TEXTURE#{i}"])
      @gl.bindTexture(@gl.TEXTURE_2D,texture)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
      @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.RGB, @gl.RGB, @gl.UNSIGNED_BYTE, img)
      @program.setUniform(sampler,i)
    img.src = url
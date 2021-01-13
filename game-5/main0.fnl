(var state {})

(fn love.load []
  (set
    state.image
    (love.graphics.newImage "assets/pig.png"))

  (set
    state.mesh
    (love.graphics.newMesh
      [
       [
        ;; top-left corner (red-tinted)
        0 0 ;; position of the vertex
        0 0 ;; texture coordinate at the vertex position
        1 0 0 ;; color of the vertex
        ]
       [
        ;; top-right corner (green-tinted)
        (state.image:getWidth) 0
        1 0 ;; texture coordinates are in the range of [0 1]
        0 1 0
        ]
       [
        ;; bottom-right corner (blue-tinted)
        (state.image:getWidth) (state.image:getHeight)
        1 1
        0 0 1
        ]
       [
        ;; bottom-left corner (yellow-tinted)
        0 (state.image:getHeight)
        0 1
        1 1 0
        ]
       ]))

  (state.mesh:setTexture state.image)
  )

(fn love.update [])

(fn love.draw []
  (love.graphics.draw state.mesh 0 0))

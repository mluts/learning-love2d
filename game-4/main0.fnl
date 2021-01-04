(var util (require :util))
(var lume (require :lume))

(var Circle
  (doto
    (util.Obj:new {:xt 0 :yt 0 :r 1 :mode "line"})
    (tset :draw
          (fn [self]
            (love.graphics.circle
              self.mode
              (util.x-coord self.xt)
              (util.y-coord self.yt)
              self.r)))))

(var Line
  (doto
    (util.Obj:new {:points []})
    (tset :draw
          (fn [self]
            (when (> (length self.points) 1)
              (let [args
                    (->
                      self.points
                      (lume.map
                        (fn [xy]
                          [(util.x-coord (. xy 1))
                           (util.y-coord (. xy 2))]))
                      (unpack)
                      (lume.concat))
                    ]
                (love.graphics.line (unpack args))))))))

(var objects {})

(fn love.load []
  (set objects.circle (Circle:new {:xt 0.3 :yt 0.3 :r 70}))
  (set objects.line1 (Line:new {:points [[0 0] [0.1 0.1]]})))

(fn love.update [dt])

(fn love.draw []
  (each [_ o (pairs objects)] (o:draw)))

(var util (require :util))
(var lume (require :lume))

(var state {})

(var Point
  (doto (util.Obj:new {:xt 0 :yt 0})))

(var Gravity
  (doto
    (util.Obj:new
      {:from-point nil
       :to-point   nil
       :acc 4
       :stop-acc 0.5
       :xv 0
       :yv 0
       :max-xv 3
       :max-yv 3
       })
    (tset :update
          (fn [self dt]
            (let [{:from-point fp
                   :to-point   tp
                   : acc
                   : stop-acc
                   : xv
                   : yv
                   : max-xv
                   : max-yv
                   } self]
              (when (not= fp.xt tp.xt)
                (let [dist (math.abs (- fp.xt tp.xt))
                      push (if
                             ; (< (math.abs (- fp.xt tp.xt)) 0.02) 0
                             (> (/ (math.abs xv) 3) dist) 0
                             (> fp.xt tp.xt) -1 1)
                      new-v   (util.new-v push
                                          ; (if (> acc dist) (/ dist 2) acc)
                                          acc
                                          stop-acc dt xv 
                                          ; 0 max-xv
                                          ; 0 (* 3 dist)
                                          )
                      new-pos (util.new-pos fp.xt new-v dt ; tp.xt fp.xt
                                      )
]
                  (set self.xv new-v)
                  (set self.from-point.xt new-pos)))

              (when (not= fp.yt tp.yt)
                (let [dist (math.abs (- fp.yt tp.yt))
                      push (if
                             (> (/ (math.abs yv) 3) dist) 0
                             (> fp.yt tp.yt) -1 1)
                      new-v   (util.new-v push
                                          acc
                                          stop-acc dt yv 
                                          ; 0 (* 3 dist)
                                          )
                      new-pos (util.new-pos fp.yt new-v dt ; tp.yt fp.yt
                                            )
                      ]
                  (set self.yv new-v)
                  (set self.from-point.yt new-pos)))
              )))))

(var Text
  (doto
    (util.Obj:new {:xt 0 :yt 0 :text "hello"})
    (tset :draw
          (fn [self]
            (love.graphics.print
              self.text
              (util.x-coord self.xt)
              (util.y-coord self.yt))))))

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
    (tset :points!
          (fn [self points] (set self.points points)))
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
                      (lume.concat))]
                (love.graphics.line (unpack args))))))))

(var objects {})

(fn love.load []
  (set objects.circle (Circle:new {:xt 0.3 :yt 0.3 :r 70}))
  (set state.mouse (Point:new {:xt 0 :yt 0}))
  ; (set objects.line1 (Line:new {:points [[0 0] [0.1 0.1]]}))
  (set objects.circle.gravity (Gravity:new
                               {:from-point objects.circle
                                :to-point state.mouse}))
  (set objects.text (Text:new {:text "Angle:" :xt 0.01 :yt 0.01})))

(fn love.update [dt]
  (let [(mouse-x mouse-y) (love.mouse.getPosition)
        mouse-xt (util.xt mouse-x)
        mouse-yt (util.yt mouse-y)
        angle (math.atan2 (- mouse-yt objects.circle.yt)
                          (- mouse-xt objects.circle.xt))]
    (set state.angle angle)
    (set objects.text.text
         (.. "Angle: " angle "\n"
             "Angle^: " (* angle (/ 180 math.pi))
             ))

    ; (set objects.line1.points [[objects.circle.xt objects.circle.yt]
    ;                            [mouse-xt mouse-yt]])

    (set state.mouse.xt mouse-xt)
    (set state.mouse.yt mouse-yt)

    (objects.circle.gravity:update dt)
    ))

(fn love.draw []
  (each [_ o (pairs objects)] (o:draw)))

(var lume (require :lume))
(var util (require :util))
(var maf (require :maf))

(var
  state
  {:r1 1
   :r2 2
   :k1 1
   :k2 5
   :theta-spacing 0.07
   :phi-spacing 0.03
   :rot-x 0 ;;(/ math.pi 4)
   :rot-z 0 ;; (/ math.pi 5)
   })

(fn new-fbuf [] {})

(fn fbuf-set [fbuf x y z]
  (doto
    fbuf
    (tset
      x
      (doto (or (. fbuf x) {})
            (tset y z)))))

(fn fbuf-get [fbuf x y]
  (or (-?> fbuf (. x) (. y)) 0))

(fn fbuf-iter [fbuf f]
  (each [x ys (pairs fbuf)]
    (each [y L (pairs ys)]
      (f x y L))))

(fn x-proj [x ooz]
  (+ (/ (love.graphics.getWidth) 2) (math.floor (* state.k1 x ooz))))

(fn y-proj [y ooz]
  (+ (/ (love.graphics.getHeight) 2) (math.floor (* state.k1 y ooz))))

(fn love.update [dt]
  (set state.rot-z (+ state.rot-z (* dt (/ math.pi 4))))
  (set state.rot-x (+ state.rot-x (* dt (/ math.pi 4))))
  (set state.k1 (+ state.k1 (* 50 dt))))

(fn love.draw []
  (local zbuf (new-fbuf))
  (local output (new-fbuf))

  (let [cos-rx (math.cos state.rot-x)
        cos-rz (math.cos state.rot-z)
        sin-rx (math.sin state.rot-x)
        sin-rz (math.sin state.rot-z)
        ]
    (for [theta 0 (* 2 math.pi) state.theta-spacing]
      (let [cos-theta (math.cos theta)
            sin-theta (math.sin theta)
            rcos0 (* state.r1 cos-theta)
            rcos (+ state.r2 rcos0)
            rsin (* state.r1 sin-theta)
            ]
        (for [phi 0 (* 2 math.pi) state.phi-spacing]
          (let [
                cos-phi (math.cos phi)
                sin-phi (math.sin phi)

                z (+ state.k2 (- (* cos-rx sin-phi rcos) (* rsin sin-rx)))

                ooz (/ 1 z)

                x (+ (* rsin cos-rx sin-rz)
                     (* rcos (+ (* sin-rx sin-phi sin-rz) (* cos-phi cos-rz))))

                y (+ (* rsin cos-rx cos-rz)
                     (* rcos (- (* sin-rx sin-phi cos-rz) (* cos-phi sin-rz))))

                norm (math.max
                       (math.abs (- (* rsin sin-rx) (* rcos0 cos-rx sin-phi)))
                       (math.abs (+ (* rsin cos-rx cos-rz) (* rcos0 (- (* sin-rx sin-phi cos-rz) (* cos-phi sin-rz)))))
                       (math.abs (+ (* rsin cos-rx sin-rz) (* rcos0 (+ (* sin-rx sin-phi sin-rz) (* cos-phi cos-rz))))))

                L (- (/ (+ (* rsin cos-rx cos-rz)
                           (* rcos0 (- (* sin-rx sin-phi cos-rz) (* cos-phi sin-rz))))
                        norm)
                     (/ (- (* rcos0 cos-rx sin-phi) (* rsin sin-rx))
                        norm))

                xp (x-proj x ooz)
                yp (y-proj y ooz)
                ]
            (when (and (< 0 L)
                       (> ooz (fbuf-get zbuf xp yp))
                       )
              (fbuf-set zbuf xp yp ooz)
              (fbuf-set output xp yp L)
              )
            )))))

  (fbuf-iter
    output
    (fn [x y L]
      (love.graphics.setColor 1 1 1 L)
      (love.graphics.points x y)
      (love.graphics.setColor 1 1 1 1)
      ))
  )


"
(cos(R_X) cos(R_Z) sin(q1) + (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)) cos(q1))
/ max(abs(sin(R_X) sin(q1) - cos(R_X) sin(R_Y) cos(q1)),
abs(cos(R_X) cos(R_Z) sin(q1) + (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)) cos(q1)),
abs(cos(R_X) sin(R_Z) sin(q1) + (sin(R_X) sin(R_Y) sin(R_Z) + cos(R_Y) cos(R_Z)) cos(q1)))
- (cos(R_X) sin(R_Y) cos(q1) - sin(R_X) sin(q1))
/ max(abs(sin(R_X) sin(q1) - cos(R_X) sin(R_Y) cos(q1)), abs(cos(R_X) cos(R_Z) sin(q1) + (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)) cos(q1)), abs(cos(R_X) sin(R_Z) sin(q1) + (sin(R_X) sin(R_Y) sin(R_Z) + cos(R_Y) cos(R_Z)) cos(q1)))


FULL_DONUT_CIRCLE;
matrix([
R1 sin(q1) cos(R_X) sin(R_Z)
+ (sin(R_X) sin(R_Y) sin(R_Z) + cos(R_Y) cos(R_Z))
(R1 cos(q1) + R2),

R1 sin(q1) cos(R_X) cos(R_Z)
+ (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z))
(R1 cos(q1) + R2),

cos(R_X) sin(R_Y) (R1 cos(q1) + R2)
- R1 sin(q1) sin(R_X)
])


LIGHTING
(R1 sin(q1) cos(R_X) cos(R_Z)
+ R1 cos(q1) (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)))
/ max(abs(R1 sin(R_X) sin(q1) - R1 cos(R_X) sin(R_Y) cos(q1)),
abs(R1 cos(R_X) cos(R_Z) sin(q1) + R1 (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)) cos(q1)),
abs(R1 cos(R_X) sin(R_Z) sin(q1) + R1 (sin(R_X) sin(R_Y) sin(R_Z) + cos(R_Y) cos(R_Z)) cos(q1)))

- (R1 cos(q1) cos(R_X) sin(R_Y) - R1 sin(R_X) sin(q1))
/ max(abs(R1 sin(R_X) sin(q1) - R1 cos(R_X) sin(R_Y) cos(q1)),
abs(R1 cos(R_X) cos(R_Z) sin(q1) + R1 (sin(R_X) sin(R_Y) cos(R_Z) - cos(R_Y) sin(R_Z)) cos(q1)),
abs(R1 cos(R_X) sin(R_Z) sin(q1) + R1 (sin(R_X) sin(R_Y) sin(R_Z) + cos(R_Y) cos(R_Z)) cos(q1)))

"

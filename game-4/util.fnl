(fn x-coord [xt] (* xt (love.graphics.getWidth)))
(fn y-coord [yt] (* yt (love.graphics.getHeight)))

(fn clamp [min max v]
  (if
    (and min (< v min)) min
    (and max (> v max)) max
    v))

(fn rect-overlap? [x11 y11 x12 y12
                   x21 y21 x22 y22]
  (and (<= x11 x22) (>= x12 x21)
       (<= y11 y22) (>= y12 y21)))

(fn lerp1 [a b t] (+ a (* t (- b a))))

(var Obj {})

(fn Obj.new [self o]
  (let [o (or o {})]
    (setmetatable o self)
    (set self.__index self)
    o))

(fn new-v [push acc stop-acc dt v min-v max-v]
  (if
    (> push 0) (clamp min-v max-v (+ v (* acc dt)))
    (< push 0) (clamp (- max-v) (- min-v) (- v (* acc dt)))
    (= 0 v) v
    (< v 0) (clamp (- max-v) (- min-v) (+ v (* stop-acc dt)))
    (> v 0) (clamp min-v max-v (- v (* stop-acc dt)))))

(fn new-pos [pos v dt min-pos max-pos]
  (->>
    (if (not= v 0)
      (+ pos (* v dt))
      pos)
    (clamp min-pos max-pos)))

{:x-coord       x-coord
 :y-coord       y-coord
 :clamp         clamp
 :rect-overlap? rect-overlap?
 :lerp          lerp1
 :Obj           Obj
 :new-v         new-v
 :new-pos       new-pos
 }

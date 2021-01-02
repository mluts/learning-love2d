;; vi: foldmethod=marker foldmarker={{{,}}}
(var Obj {})
(var TxtObj {})
(var player {})
(var Pos {})
(var Bullet {})
(var bullets [])

;; {{{ Utils
(fn x-coord [xt] (* xt (love.graphics.getWidth)))
(fn y-coord [yt] (* yt (love.graphics.getHeight)))

(fn sin-wave [min-y max-y x-cycle x]
  (+ min-y
     (* (- max-y min-y)
        (/ (+ 1 (math.sin (-
                            (* (/ x x-cycle) (math.rad 90))
                            (math.rad 90))))
           2))))

(fn clamp [min max v]
  (if
    (and min (< v min)) min
    (and max (> v max)) max
    v))

(fn lerp1 [a b t] (+ a (* t (- b a))))

(fn new-pos [pos v dt min-pos max-pos]
  (->>
    (if (not= v 0)
      (+ pos (* v dt))
      pos)
    (clamp min-pos max-pos)))

(fn new-v [push acc stop-acc dt v min-v max-v]
  (if
    (> push 0) (clamp min-v max-v (+ v (* acc dt)))
    (< push 0) (clamp (- max-v) (- min-v) (- v (* acc dt)))
    (= 0 v) v
    (< v 0) (clamp (- max-v) (- min-v) (+ v (* stop-acc dt)))
    (> v 0) (clamp min-v max-v (- v (* stop-acc dt)))))

(fn Obj.new [self o]
  (let [o (or o {})]
    (setmetatable o self)
    (set self.__index self)
    o))
;; }}}

;; {{{ TxtObj
(set TxtObj
     (Obj:new
       {:text ""
        :xt 0 :yt 0
        :r 0
        :sx 1 :sy 1}))

(fn TxtObj.draw [self]
  (love.graphics.print
    self.text
    (x-coord self.xt)
    (y-coord self.yt)
    self.r
    self.sx self.sy
    self.ox self.oy
    self.kx self.ky))

(fn TxtObj.width [self]
  (let [font (love.graphics.getFont)]
    (font:getWidth self.text)))

(fn TxtObj.twidth [self]
  (/ (self:width) (love.graphics.getWidth)))

(fn TxtObj.height [_]
  (let [font (love.graphics.getFont)]
    (font:getHeight)))

(fn TxtObj.theight [self]
  (/ (self:height) (love.graphics.getHeight)))

(fn TxtObj.visible? [self]
  (and (<= 0 self.xt 1) (<= 0 self.yt 1)))

;; }}}

;; {{{ Pos
(set
  Pos
  (doto
    (Obj:new {:acc      1000
              :stop-acc 1000
              :max-v    1
              :v        0
              :pos      0
              :push     0})
    (tset :push-left! (fn [self] (set self.push -1)))
    (tset :push-right! (fn [self] (set self.push 1)))
    (tset :no-push! (fn [self] (set self.push 0)))
    (tset :update! (fn [self dt min-pos max-pos]
                     (let [{: acc : stop-acc : max-v : v : pos : push} self]
                       (doto self
                             (tset :pos (new-pos pos v dt min-pos max-pos))
                             (tset :v (new-v push acc stop-acc dt v 0 max-v))))))))

;; }}}

;; {{{ Bullet
(set
  Bullet
  (doto
    (TxtObj:new {:text "pow!" :r (math.rad -90)})
    (tset :new (fn [self xt yt]
                 (let [o (doto {:xt 0
                                :yt 0
                                :orig-xt xt
                                :orig-yt yt
                                :pos-x (Pos:new {:acc 0 :stop-acc 0 :max-v 0 :v 0 :pos 0 :push 0})
                                :pos-y (Pos:new {:acc 4 :stop-acc 0 :max-v 0.6 :v -0.6 :pos 0 :push -1})}
                               (setmetatable self))]
                   (set self.__index self)
                   o)))
    (tset :update (fn [self dt]
                    (self.pos-y:update! dt)
                    (self.pos-x:update! dt)
                    (set self.xt (+ self.orig-xt self.pos-x.pos))
                    (set self.yt (+ self.orig-yt self.pos-y.pos))))))

;; }}}

;; {{{player
(set
  player
  (doto
    (TxtObj:new {:orig-xt 0.5
                 :orig-yt 0.9
                 :xt      0
                 :yt      0
                 :text "player"
                 :pos-x (Pos:new {:acc 4 :stop-acc 1000 :max-v 1 :v 0 :pos 0 :push 0})
                 :pos-y (Pos:new {:acc 4 :stop-acc 1000 :max-v 1 :v 0 :pos 0 :push 0})})

    (tset :update (fn [self dt]
                    (self.pos-x:update! dt (- self.orig-xt) (- 1 (+ self.orig-xt (self:twidth))))
                    (self.pos-y:update! dt (- self.orig-yt) (- 1 (+ self.orig-yt (self:theight))))
                    (set self.xt (+ self.orig-xt self.pos-x.pos))
                    (set self.yt (+ self.orig-yt self.pos-y.pos))))

    (tset :move-left (fn [self dt] (self.pos-x:push-left!)))
    (tset :move-right (fn [self dt] (self.pos-x:push-right!)))
    (tset :move-up (fn [self dt] (self.pos-y:push-left!)))
    (tset :move-down (fn [self dt] (self.pos-y:push-right!)))
    (tset :no-move-x (fn [self] (self.pos-x:no-push!)))
    (tset :no-move-y (fn [self] (self.pos-y:no-push!)))

    (tset :shoot (fn [self]
                   (table.insert bullets
                                 (Bullet:new
                                   (+ self.xt (/ (self:twidth) 2))
                                   (- self.yt (self:theight))))))))
;; }}}

(fn love.load [])

(fn love.draw []
  (player:draw)
  (each [_ bullet (ipairs bullets)] (bullet:draw)))

(fn love.update [dt]
  (if
    (love.keyboard.isDown "left") (player:move-left dt)
    (love.keyboard.isDown "right") (player:move-right dt)
    (player:no-move-x))

  (player:update dt)

  (let [not-visible []]
    (each [i bullet (ipairs bullets)]
      (when (not (bullet:visible?)) (table.insert not-visible i))
      (bullet:update dt))
    (each [_ i (ipairs not-visible)]
      (table.remove bullets i))))

(fn love.keyreleased [key]
  (match key
    "up"  (player:shoot)))

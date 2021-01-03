;; vi: foldmethod=marker foldmarker={{{,}}}
(var Obj {})
(var TxtObj {})
(var player {})
(var enemy {})
(var Pos {})
(var Bullet {})
(var bullets [])
(var stats {})

;; {{{ fonts
(var fonts {})
(fn fonts.load [self]
  (doto self
        (tset :default (love.graphics.newFont))
        (tset :player (love.graphics.newFont 20)))
  (love.graphics.setFont self.default))

(fn fonts.with-font [self font f]
  (if font
    (do
      (love.graphics.setFont font)
      (let [res (f)]
        (love.graphics.setFont self.default)
        res))
    (f)))
;; }}}

;; {{{ Utils
(fn x-coord [xt] (* xt (love.graphics.getWidth)))
(fn y-coord [yt] (* yt (love.graphics.getHeight)))

;; https://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
;; https://silentmatt.com/rectangle-intersection/
(fn rect-overlap? [x11 y11 x12 y12
                   x21 y21 x22 y22]
  (and (<= x11 x22) (>= x12 x21)
       (<= y11 y22) (>= y12 y21)))

(fn obj->rect [obj]
  (values
    obj.xt
    obj.yt
    (+ obj.xt (obj:twidth))
    (+ obj.yt (obj:theight))))

(fn obj-overlap? [obj1 obj2]
  (let [(x11 y11 x12 y12) (obj->rect obj1)
        (x21 y21 x22 y22) (obj->rect obj2)]
    (rect-overlap? x11 y11 x12 y12
                   x21 y21 x22 y22)))

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
  (fonts:with-font
    self.font
    (fn []
      (love.graphics.print
        self.text
        (x-coord self.xt)
        (y-coord self.yt)
        self.r
        self.sx self.sy
        self.ox self.oy
        self.kx self.ky))))

(fn TxtObj.width [self]
  (let [font (or self.font (love.graphics.getFont))]
    (font:getWidth self.text)))

(fn TxtObj.twidth [self]
  (/ (self:width) (love.graphics.getWidth)))

(fn TxtObj.height [self]
  (let [font (or self.font (love.graphics.getFont))]
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
                                :pos-y (Pos:new {:acc 2 :stop-acc 0 :max-v 2 :v -0.6 :pos 0 :push -1})}
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
(fn load-player []
  (set
    player
    (doto
      (TxtObj:new {:orig-xt 0.5
                   :orig-yt 0.9
                   :xt      0
                   :yt      0
                   :text "player"
                   :font fonts.player
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
                                     (- self.yt (self:theight)))))))))
;; }}}

;; {{{ enemy
(fn load-enemy []
  (set
    enemy
    (doto
      (TxtObj:new {:orig-xt 0.5
                   :orig-yt 0.01
                   :xt 0
                   :yt 0
                   :text "enemy"
                   :font fonts.player
                   :pos-x (Pos:new {:acc 4 :stop-acc 1000 :max-v 0.2 :v 0 :pos 0 :push 0})

                   :movement-period 0})
      (tset :move-oscillate
            (fn [self dt]
              (set self.movement-period
                   (+ self.movement-period
                      (* (/ dt 4) (math.rad 360))))))
      (tset :update (fn [self dt]
                      (self:move-oscillate dt)
                      (let [x (math.sin self.movement-period)]
                        (if
                          (< (math.abs x) 0.01) (self.pos-x:no-push!)
                          (< x 0) (self.pos-x:push-left!)
                          (> x 0) (self.pos-x:push-right!)))
                      (self.pos-x:update! dt (- self.orig-xt) (- 1 (+ self.orig-xt (self:twidth))))
                      (set self.xt (+ self.orig-xt self.pos-x.pos))
                      )))))
;;}}}

;; {{{ stats
(fn load-stats []
  (set
    stats
    (doto
      {:hits 0}
      (tset :inc-hits! (fn [self]
                         (set self.hits (+ self.hits 1))))
      (tset :draw (fn [self]
                    (love.graphics.print 
                      (.. "hits: "  self.hits)
                      (x-coord 0)
                      (y-coord 0.2)
                      ))))))
;;}}}

(fn love.load []
  (fonts:load)
  (load-player)
  (load-enemy)
  (load-stats))

(fn love.draw []
  (player:draw)
  (enemy:draw)
  (stats:draw)
  (each [_ bullet (ipairs bullets)] (bullet:draw)))

(fn love.update [dt]
  (enemy:update dt)

  (if
    (love.keyboard.isDown "left") (player:move-left dt)
    (love.keyboard.isDown "right") (player:move-right dt)
    (player:no-move-x))

  (player:update dt)

  (let [not-visible []
        enemy-hit   []]
    (each [i bullet (ipairs bullets)]
      (if
        (not (bullet:visible?)) (table.insert not-visible i)
        (obj-overlap? enemy bullet) (table.insert enemy-hit i))
      (bullet:update dt))
    (each [_ i (ipairs not-visible)]
      (table.remove bullets i))
    (each [_ i (ipairs enemy-hit)]
      (do
        (stats:inc-hits!)
        (table.remove bullets i)))))

(fn love.keyreleased [key]
  (match key
    "up"  (player:shoot)))

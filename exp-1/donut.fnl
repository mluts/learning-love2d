(fn system [cmd]
  (let [handle          (assert (io.popen cmd "r"))
        cmd-out         (assert (handle:read "*a"))
        (_ _ exit-code) (handle:close)]
    (values cmd-out exit-code)))

(var term {})

(fn term.init [self]
  (set term.reset-str (system "tput reset"))
  (set term.reset-str (system "tput reset"))
  )

(fn term.reset [self]
  (io.write self.reset-str))

(fn term.mv [self row col]
  (io.write (.. "\27[" (+ 1 row) ";" (+ 1 col) "H")))

(fn term.put-ch [self ch]
  (io.write ch))

(term:init)

(fn draw [dt]
  (term:reset)
  (term:mv 10 10)
  (term:put-ch "W")
  (term:mv 10 11)
  (term:put-ch "W")
  (term:mv 10 12)
  (term:put-ch "W")
  (term:mv 0 0)
  )

(fn main []
  (var t1 (os.clock))
  (var t2 (os.clock))
  (local framerate (/ 1 15))
  (while true
    (set t2 (os.clock))
    (draw (- t2 t1))
    (set t1 t2)))

(global
  donut
  {:system system
   :term term
   :main main
   })

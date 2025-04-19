[
  (set)
  (let)
  (show)
  (call)
] @indent.begin

[
  "]"
  "}"
  ")"
] @indent.branch @indent.end


; [
;   (set)
;   (let)
;   (show)
;   (call)
; ] @indent.begin

("{" @indent.
   (#set! indent.immediate 1))
; ((code) @indent.
;   (#set! indent.immediate 1))
;
; ((block) @indent.begin
;   (#set! indent.immediate 1))

; ((call) @indent.begin
;   (#set! indent.immediate 1))
; ("{" @indent.begin @indent.branch
;   (#set! indent.immediate 1))
;
((ERROR (call)) @indent.begin
  (#set! indent.immediate 1))

; [
;   "]"
;   "}"
;   ")"
; ] @indent.branch @indent.end


; Created by The GroggyOtter
class Viewport {
    #Requires AutoHotkey 2.0+
    static keys :=  {activate  : 'F1'                                                               ; Enable/disable viewporting
                    ,make_move : '+LButton'                                                         ; Make new/move existing viewport
                    ,toggle    : '+MButton'                                                         ; Toggle viewport overlay
                    ,resize    : '+RButton'                                                         ; Adjust width/length
                    ,alpha_dec : '+WheelDown'                                                       ; Make viewport black more opaque
                    ,alpha_inc : '+WheelUp' }                                                       ; Make viewport black more transparent
    
    static alpha    := 230                                                                          ; Default alpha value (0-255)
        , alpha_inc := 8                                                                            ; Alpha adjustment amount
    
    static __New() {
        vpo := viewport()
        ,keys := this.keys
        ,hk_mod := '#!^+<>*~$'
        Hotkey(keys.activate, (*) => vpo.toggle())
        HotIf((*) => vpo.active)
        obm := ObjBindMethod(vpo, "start_viewport", LTrim(keys.make_move, hk_mod))
        Hotkey(keys.make_move, obm)
        Hotkey(keys.toggle, (*) => vpo.toggle_gui())
        obm := ObjBindMethod(vpo, "resize_pre", LTrim(keys.resize, hk_mod))
        Hotkey(keys.resize, obm)
        Hotkey(keys.alpha_inc, (*) => vpo.alpha_adj(Viewport.alpha_inc))
        Hotkey(keys.alpha_dec, (*) => vpo.alpha_adj(Viewport.alpha_inc * -1))
        HotIf()
    }
    
    ; Instance initialize
    active := 1, x1 := 0, y1 := 0, x2 := 0, y2 := 0, gui := Gui(), reg1 := ''
    gui_id => 'ahk_id' this.gui.hwnd
    
    alpha {
        get => this._alpha
        set => this._alpha := value < 0 ? 0 : value > 255 ? 255 : value
    }

    __New() => (this.alpha := Viewport.alpha, this.make_black_overlay())
    
    start_viewport(hk, *) {
        if this.cursor_in_viewport()
            WinActivate(this.gui_id)
            ,this.cursor_update()
            ,this.move_viewport(hk, this.cx, this.cy)
        else
            this.update_trans()
            ,this.show()
            ,this.cursor_update()
            ,this.x1 := this.x2 := this.cx
            ,this.y1 := this.y2 := this.cy
            ,this.make_viewport(hk)
    }
    
    make_viewport(hk) {
        this.cursor_update()
        if GetKeyState(hk, 'P')
            this.update_viewport(this.x1, this.y1, this.cx, this.cy)
            ,obm := ObjBindMethod(this, "make_viewport", hk)
            ,SetTimer(obm, -1)
        else this.x2 := this.cx, this.y2 := this.cy
        this.coord_update()
    }
    
    move_viewport(hk, x1, y1) {
        this.cursor_update()
        ,xdiff := this.cx - x1, ydiff := this.cy - y1
        if GetKeyState(hk, 'P')
            this.update_viewport(this.x1 + xdiff, this.y1 + ydiff, this.x2 + xdiff, this.y2 + ydiff)
            ,obm := ObjBindMethod(this, "move_viewport", hk, x1, y1)
            ,SetTimer(obm, -1)
        else this.x1 += xdiff, this.x2 += xdiff, this.y1 += ydiff, this.y2 += ydiff
        this.coord_update()
    }
    
    resize_viewport(hk, x1, y1) {
        this.cursor_update()
        ,xdiff := x1 - this.cx, ydiff := y1 - this.cy
        if GetKeyState(hk, 'P')
            this.update_viewport(this.x1 + xdiff, this.y1 - ydiff, this.x2 - xdiff, this.y2 + ydiff)
            ,obm := ObjBindMethod(this, "resize_viewport", hk, x1, y1)
            ,SetTimer(obm, -1)
        else this.x1 += xdiff, this.x2 -= xdiff, this.y1 -= ydiff, this.y2 += ydiff
        this.coord_update()
    }
    
    coord_update() {
        (this.x2 < this.x1) ? (tmp := this.x2, this.x2 := this.x1, this.x1 := tmp) : 0
        ,(this.y2 < this.y1) ? (tmp := this.y2, this.y2 := this.y1, this.y1 := tmp) : 0
    }
    
    cursor_update() {
        CoordMode('Mouse', 'Client')
        ,MouseGetPos(&x, &y)
        ,this.cx := x, this.cy := y
        ,CoordMode('Mouse', 'Screen')
        ,MouseGetPos(&x, &y)
        ,this.sx := x, this.sy := y
    }
    
    make_black_overlay() {
        x := y := r := b := 0
        loop MonitorGetCount()
            MonitorGet(A_Index, &mx, &my, &mr, &mb)
            ,mx < x ? x := mx : 0
            ,my < y ? y := my : 0
            ,mr > r ? r := mr : 0
            ,mb > b ? b := mb : 0
        w := Abs(x) + Abs(r), h := Abs(y) + Abs(b)
        ,this.gui := goo := Gui('+AlwaysOnTop -Caption -DPIScale')
        ,goo.x := x, goo.y := y, goo.w := w, goo.h := h
        ,goo.BackColor := 0x000000
        ,goo.region := this.region(x, y, x + w, y + h)
    }
    
    cursor_in_viewport() {
        MouseGetPos(&x, &y, &w)
        return !WinExist(this.gui_id) ? 0 : (w = this.gui.hwnd) ? 0 : 1 
    }
    
    update_viewport(x1, y1, x2, y2) => WinActive(this.gui_id) ? WinSetRegion(this.gui.region ' ' this.region(x1, y1, x2, y2), this.gui_id) : 0
    region(x1,y1,x2,y2) => x1 '-' y1 ' ' x2 '-' y1 ' ' x2 '-' y2 ' ' x1 '-' y2 ' ' x1 '-' y1
    toggle(*) => (this.active := !this.active, this.active ? 1 : this.gui.Hide())
    toggle_gui(*) => (WinExist(this.gui_id) ? this.gui.Hide() : this.gui.Show())
    resize_pre(hk, *) => (this.cursor_update(), this.resize_viewport(hk, this.cx, this.cy))
    update_trans() => WinSetTransparent(this.alpha, this.gui)
    show() => this.gui.Show('x' this.gui.x ' y' this.gui.y ' w' this.gui.w ' h' this.gui.h)
    alpha_adj(n:=0) => (this.alpha += n, this.update_trans(), this.notify('Alpha: ' this.alpha))
    notify(msg) => (ToolTip(msg), SetTimer((*)=>ToolTip(), -1000))
}

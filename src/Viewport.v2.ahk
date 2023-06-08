; Created by The GroggyOtter
class Viewport {
    #Requires AutoHotkey 2.0+
    static keys :=  {activate  : '+F1'           ; Enable/disable viewporting
                    ,make_move : '+LButton'      ; Make new/move existing viewport
                    ,toggle    : '+MButton'      ; Toggle viewport overlay
                    ,resize    : '+RButton'      ; Adjust width/length
                    ,alpha_dec : '+WheelDown'    ; Make viewport black more opaque
                    ,alpha_inc : '+WheelUp' }    ; Make viewport black more transparent
    
    static alpha    := 240                       ; Default alpha value (0-255)
        , alpha_inc := 8                         ; Alpha adjustment amount
    ;============================================
    static version := 1.1
    static hk_mod  := '#!^+<>*~$'
    
    static __New() {
        vpo := viewport()
        Hotkey(this.keys.activate, (*) => vpo.toggle())
        HotIf((*) => vpo.active)
        Hotkey(this.keys.make_move, ObjBindMethod(vpo, "start_viewport", this.strip_mod(this.keys.make_move)))
        Hotkey(this.keys.toggle, (*) => vpo.toggle_gui())
        Hotkey(this.keys.resize, ObjBindMethod(vpo, "resize_anchor", this.strip_mod(this.keys.resize)))
        Hotkey(this.keys.alpha_inc, (*) => vpo.alpha_adj(Viewport.alpha_inc))
        Hotkey(this.keys.alpha_dec, (*) => vpo.alpha_adj(Viewport.alpha_inc * -1))
        HotIf()
    }
    
    static strip_mod(hk) {
        loop (StrLen(hk) - 1)
            if InStr(this.hk_mod, SubStr(hk, 1, 1))
                hk := SubStr(hk, 2)
            else Break
        return hk
    }
    
    ; Instance initialize
    active := 1, gui := Gui(), x1 := 0, y1 := 0, x2 := 0, y2 := 0, last_x := 0, last_y := 0
    
    __New() => (CoordMode('Mouse', 'Client')
            ,this.alpha := Viewport.alpha
            ,this.mouse := Viewport.mouse()
            ,this.make_black_overlay() )
    
    alpha {
        get => this._alpha
        set => this._alpha := (value < 0) ? 0 : (value > 255) ? 255 : value
    }
    
    gui_id              => 'ahk_id' this.gui.hwnd
    region(x1,y1,x2,y2) => x1 '-' y1 ' ' x2 '-' y1 ' ' x2 '-' y2 ' ' x1 '-' y2 ' ' x1 '-' y1
    toggle(*)           => (this.active := !this.active) ? 1 : this.gui.Hide()
    toggle_gui(*)       => WinExist(this.gui.ahk) ? this.gui.Hide() : this.gui.Show()
    update_trans()      => WinSetTransparent(this.alpha, this.gui)
    show()              => (this.gui.Show('x' this.gui.x ' y' this.gui.y ' w' this.gui.w ' h' this.gui.h)
                            ,WinWaitActive(this.gui.ahk) )
    alpha_adj(n)        => (this.alpha += n
                            ,this.update_trans()
                            ,this.notify('Alpha: ' this.alpha) )
    notify(msg)         => (ToolTip(msg)
                            ,SetTimer((*)=>ToolTip(), -850) )
    check_again(hk, m)  => GetKeyState(hk, 'P') ? SetTimer(ObjBindMethod(this, m, hk), -1) : 0
    
    start_viewport(hk, *) {
        if this.cursor_in_viewport()
            this.last_x := this.mouse.x
            ,this.last_y := this.mouse.y
            ,this.move_viewport(hk)
        else
            this.update_trans()
            ,this.show()
            ,this.x1 := this.mouse.x
            ,this.y1 := this.mouse.y
            ,this.update_viewport(hk)
    }
    
    update_viewport(hk) {
        this.x2 := this.mouse.x
        ,this.y2 := this.mouse.y
        ,this.update_region()
        ,this.check_again(hk, 'update_viewport')
    }
        
    move_viewport(hk) {    
        xd := (x := this.mouse.x) - this.last_x
        ,yd := (y := this.mouse.y) - this.last_y
        ,this.x1 += xd, this.x2 += xd, this.y1 += yd, this.y2 += yd
        ,this.last_x := x, this.last_y := y
        ,this.update_region()
        ,this.check_again(hk, 'move_viewport')
    }
    
    resize_anchor(hk, *) {
        this.last_x := this.mouse.x
        ,this.last_y := this.mouse.y
        ,this.resize_viewport(hk)
    }
    
    resize_viewport(hk, *) {
        xdiff := this.last_x - (x := this.mouse.x)
        ,ydiff := this.last_y - (y := this.mouse.y)
        ,this.x1 += xdiff, this.x2 -= xdiff, this.y1 += ydiff, this.y2 -= ydiff
        ,this.last_x := x, this.last_y := y
        ,this.update_region()
        ,this.check_again(hk, 'resize_viewport')
    }
    
    make_black_overlay() {
        x := y := r := b := 0
        loop MonitorGetCount()
            MonitorGet(A_Index, &mx, &my, &mr, &mb)
            ,mx < x ? x := mx : 0
            ,my < y ? y := my : 0
            ,mr > r ? r := mr : 0
            ,mb > b ? b := mb : 0
        this.gui      := goo := Gui('+AlwaysOnTop -Caption -DPIScale')
        ,goo.BackColor := 0x000000
        ,goo.ahk       := 'ahk_id ' goo.hwnd
        ,goo.x         := x, goo.y := y, goo.w := Abs(x) + Abs(r), goo.h := Abs(y) + Abs(b)
        ,goo.region    := this.region(0, 0, goo.w, goo.h)
    }
    
    cursor_in_viewport() => !WinExist(this.gui.ahk) ? 0 : (this.mouse.win = this.gui.hwnd) ? 0 : 1 
    
    update_region() => WinExist(this.gui.ahk) 
        ? WinSetRegion(this.gui.region ' ' this.region(this.x1, this.y1, this.x2, this.y2), this.gui.ahk) : 0
    
    class mouse {
        x   => this.get('x')
        y   => this.get('y')
        win => this.get('w')
        
        get(id) {
            (A_CoordModeMouse = 'Client' ? 0 : CoordMode('Mouse', 'Client'))
            ,MouseGetPos(&x, &y, &w)
            return %id%
        }
    }
}

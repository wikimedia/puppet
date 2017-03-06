"CLASS: MenuController
"============================================================
let s:MenuController = {}
let g:NERDTreeMenuController = s:MenuController

"FUNCTION: MenuController.New(menuItems) {{{1
"create a new menu controller that operates on the given menu items
function! s:MenuController.New(menuItems)
    let newMenuController =  copy(self)
    if a:menuItems[0].isSeparator()
        let newMenuController.menuItems = a:menuItems[1:-1]
    else
        let newMenuController.menuItems = a:menuItems
    endif
    return newMenuController
endfunction

"FUNCTION: MenuController.showMenu() {{{1
"start the main loop of the menu and get the user to choose/execute a menu
"item
function! s:MenuController.showMenu()
    call self._saveOptions()

    try
        let self.selection = 0

        let done = 0
        while !done
            redraw!
            call self._echoPrompt()
            let key = nr2char(getchar())
            let done = self._handleKeypress(key)
        endwhile
    finally
        call self._restoreOptions()
    endtry

    if self.selection != -1
        let m = self._current()
        call m.execute()
    endif
endfunction

"FUNCTION: MenuController._echoPrompt() {{{1
function! s:MenuController._echoPrompt()
    echo "NERDTree Menu. Use j/k/enter and the shortcuts indicated"
    echo "=========================================================="

    for i in range(0, len(self.menuItems)-1)
        if self.selection == i
            echo "> " . self.menuItems[i].text
        else
            echo "  " . self.menuItems[i].text
        endif
    endfor
endfunction

"FUNCTION: MenuController._current(key) {{{1
"get the MenuItem that is currently selected
function! s:MenuController._current()
    return self.menuItems[self.selection]
endfunction

"FUNCTION: MenuController._handleKeypress(key) {{{1
"change the selection (if appropriate) and return 1 if the user has made
"their choice, 0 otherwise
function! s:MenuController._handleKeypress(key)
    if a:key == 'j'
        call self._cursorDown()
    elseif a:key == 'k'
        call self._cursorUp()
    elseif a:key == nr2char(27) "escape
        let self.selection = -1
        return 1
    elseif a:key == "\r" || a:key == "\n" "enter and ctrl-j
        return 1
    else
        let index = self._nextIndexFor(a:key)
        if index != -1
            let self.selection = index
            if len(self._allIndexesFor(a:key)) == 1
                return 1
            endif
        endif
    endif

    return 0
endfunction

"FUNCTION: MenuController._allIndexesFor(shortcut) {{{1
"get indexes to all menu items with the given shortcut
function! s:MenuController._allIndexesFor(shortcut)
    let toReturn = []

    for i in range(0, len(self.menuItems)-1)
        if self.menuItems[i].shortcut == a:shortcut
            call add(toReturn, i)
        endif
    endfor

    return toReturn
endfunction

"FUNCTION: MenuController._nextIndexFor(shortcut) {{{1
"get the index to the next menu item with the given shortcut, starts from the
"current cursor location and wraps around to the top again if need be
function! s:MenuController._nextIndexFor(shortcut)
    for i in range(self.selection+1, len(self.menuItems)-1)
        if self.menuItems[i].shortcut == a:shortcut
            return i
        endif
    endfor

    for i in range(0, self.selection)
        if self.menuItems[i].shortcut == a:shortcut
            return i
        endif
    endfor

    return -1
endfunction

"FUNCTION: MenuController._setCmdheight() {{{1
"sets &cmdheight to whatever is needed to display the menu
function! s:MenuController._setCmdheight()
    let &cmdheight = len(self.menuItems) + 3
endfunction

"FUNCTION: MenuController._saveOptions() {{{1
"set any vim options that are required to make the menu work (saving their old
"values)
function! s:MenuController._saveOptions()
    let self._oldLazyredraw = &lazyredraw
    let self._oldCmdheight = &cmdheight
    set nolazyredraw
    call self._setCmdheight()
endfunction

"FUNCTION: MenuController._restoreOptions() {{{1
"restore the options we saved in _saveOptions()
function! s:MenuController._restoreOptions()
    let &cmdheight = self._oldCmdheight
    let &lazyredraw = self._oldLazyredraw
endfunction

"FUNCTION: MenuController._cursorDown() {{{1
"move the cursor to the next menu item, skipping separators
function! s:MenuController._cursorDown()
    let done = 0
    while !done
        if self.selection < len(self.menuItems)-1
            let self.selection += 1
        else
            let self.selection = 0
        endif

        if !self._current().isSeparator()
            let done = 1
        endif
    endwhile
endfunction

"FUNCTION: MenuController._cursorUp() {{{1
"move the cursor to the previous menu item, skipping separators
function! s:MenuController._cursorUp()
    let done = 0
    while !done
        if self.selection > 0
            let self.selection -= 1
        else
            let self.selection = len(self.menuItems)-1
        endif

        if !self._current().isSeparator()
            let done = 1
        endif
    endwhile
endfunction

" vim: set sw=4 sts=4 et fdm=marker:

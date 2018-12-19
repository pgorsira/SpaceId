import Cocoa
import Foundation
import ServiceManagement

class StatusItem: NSObject, NSMenuDelegate {
    
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let defaults = UserDefaults.standard
    private let buttonImage = ButtonImage()
    private var currentSpaceInfo = SpaceInfo(keyboardFocusSpace: nil, activeSpaces: [], allSpaces: [])
    
    var delegate: ReloadDelegate? = nil
    
    func createMenu() {
        item.menu = menuItems()
    }
    
    func updateMenuImage(spaceInfo: SpaceInfo) {
        currentSpaceInfo = spaceInfo
        item.button?.image = buttonImage.createImage(spaceInfo: spaceInfo)
    }
    
    private func menuItems() -> NSMenu {
        let menu = NSMenu()
        let pref = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        let opt = NSMenuItem(title: "Options", action: nil, keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "")
        quit.target = self
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "0"
        menu.addItem(NSMenuItem(title: "v\(version)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(pref)
        menu.setSubmenu(preferenceMenu(), for: pref)
        menu.addItem(opt)
        menu.setSubmenu(optionMenu(), for: opt)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quit)
        return menu
    }
    
    private func preferenceMenu() -> NSMenu {
        let menu = NSMenu()
        let oneIcon = NSMenuItem(title: "One Icon",
                                 action: #selector(oneIcon(_:)),
                                 keyEquivalent: "")
        let perMonitor = NSMenuItem(title: "Icon Per Monitor",
                                    action: #selector(iconPerMonitor(_:)),
                                    keyEquivalent: "")
        let perSpace = NSMenuItem(title: "Icon Per Space",
                                  action: #selector(iconPerSpace(_:)),
                                  keyEquivalent: "")
        let fill = NSMenuItem(title: "White on Black",
                              action: #selector(whiteOnBlack(_:)),
                              keyEquivalent: "")
        let empty = NSMenuItem(title: "Black on White",
                               action: #selector(blackOnWhite(_:)),
                               keyEquivalent: "")
        let launchLogin = NSMenuItem(title: "Launch on Login",
                                     action: #selector(launchOnLogin(_:)),
                                     keyEquivalent: "")
        
        oneIcon.target = self
        perMonitor.target = self
        perSpace.target = self
        fill.target = self
        empty.target = self
        launchLogin.target = self
        
        switch defaults.integer(forKey: Preference.icon) {
        case 0: oneIcon.state = .on
        case 1: perMonitor.state = .on
        case 2: perSpace.state = .on
        default: break
        }
        
        switch defaults.integer(forKey: Preference.color) {
        case 0: fill.state = .on
        case 1: empty.state = .on
        default: break
        }
        
        launchLogin.state = defaults.bool(forKey: Preference.App.launchOnLogin.rawValue) ? .on : .off
        
        menu.addItem(launchLogin)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(oneIcon)
        menu.addItem(perMonitor)
        menu.addItem(perSpace)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(fill)
        menu.addItem(empty)
        return menu
    }
    
    private func optionMenu() -> NSMenu {
        let menu = NSMenu()
        let leftClick = NSMenuItem(title: "Update on Left Click",
                                   action: #selector(updateOnLeftClick(_:)),
                                   keyEquivalent: "")
        let appSwitch = NSMenuItem(title: "Update on Application Switch",
                                   action: #selector(updateOnAppSwitch(_:)),
                                   keyEquivalent: "")


        leftClick.target = self
        appSwitch.target = self
        
        leftClick.state = defaults.bool(forKey: Preference.App.updateOnLeftClick.rawValue) ? .on : .off
        appSwitch.state = defaults.bool(forKey: Preference.App.updateOnAppSwitch.rawValue) ? .on : .off
        
        menu.addItem(NSMenuItem(title: "Enhance Multi Monitor Support", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(leftClick)
        menu.addItem(appSwitch)
        return menu
    }
    
    @objc func oneIcon(_ sender: NSMenuItem) {
        defaults.set(Preference.Icon.one.rawValue, forKey: Preference.icon)
        createMenu()
        updateMenuImage(spaceInfo: currentSpaceInfo)
    }
    
    @objc func iconPerMonitor(_ sender: NSMenuItem) {
        defaults.set(Preference.Icon.perMonitor.rawValue, forKey: Preference.icon)
        createMenu()
        updateMenuImage(spaceInfo: currentSpaceInfo)
    }
    
    @objc func iconPerSpace(_ sender: NSMenuItem) {
        defaults.set(Preference.Icon.perSpace.rawValue, forKey: Preference.icon)
        createMenu()
        updateMenuImage(spaceInfo: currentSpaceInfo)
    }
    
    @objc func whiteOnBlack(_ sender: NSMenuItem) {
        defaults.set(Preference.Color.whiteOnBlack.rawValue, forKey: Preference.color)
        createMenu()
        updateMenuImage(spaceInfo: currentSpaceInfo)
    }
    
    @objc func blackOnWhite(_ sender: NSMenuItem) {
        defaults.set(Preference.Color.blackOnWhite.rawValue, forKey: Preference.color)
        createMenu()
        updateMenuImage(spaceInfo: currentSpaceInfo)
    }
    
    @objc func updateOnLeftClick(_ sender: NSMenuItem) {
        let b = defaults.bool(forKey: Preference.App.updateOnLeftClick.rawValue)
        defaults.set(!b, forKey: Preference.App.updateOnLeftClick.rawValue)
        delegate?.reload()
    }

    @objc func updateOnAppSwitch(_ sender: NSMenuItem) {
        let b = defaults.bool(forKey: Preference.App.updateOnAppSwitch.rawValue)
        defaults.set(!b, forKey: Preference.App.updateOnAppSwitch.rawValue)
        delegate?.reload()
    }
    
    @objc func launchOnLogin(_ sender: NSMenuItem) {
        let b = !defaults.bool(forKey: Preference.App.launchOnLogin.rawValue)
        defaults.set(b, forKey: Preference.App.launchOnLogin.rawValue)
        delegate?.reload()
    }

    @objc func quit(_ sender: NSMenuItem) {
        NSApp.terminate(self)
    }
    
}


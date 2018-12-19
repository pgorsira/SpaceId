import Cocoa

class SpaceIdentifier {
    
    let conn = _CGSDefaultConnection()
    let defaults = UserDefaults.standard
    
    typealias ScreenNumber = String
    typealias ScreenUUID = String
    
    func getMonitors() -> [[String : Any]]{
        return (CGSCopyManagedDisplaySpaces(conn) as? [[String : Any]])!
    }
    
    func getSpaceInfo() -> SpaceInfo {
        guard let monitors = CGSCopyManagedDisplaySpaces(conn) as? [[String : Any]],
            let mainDisplay = NSScreen.main,
              let screenNumber = mainDisplay.deviceDescription[NSDeviceDescriptionKey(rawValue: ("NSScreenNumber"))] as? UInt32
        else { return SpaceInfo(keyboardFocusSpace: nil, activeSpaces: [], allSpaces: []) }
        
        let cfuuid = CGDisplayCreateUUIDFromDisplayID(screenNumber).takeRetainedValue()
        let screenUUID = CFUUIDCreateString(kCFAllocatorDefault, cfuuid) as String
        let (activeSpaces, allSpaces) = parseSpaces(monitors: monitors)

        return SpaceInfo(keyboardFocusSpace: activeSpaces[screenUUID],
                         activeSpaces: activeSpaces.map{ $0.value },
                         allSpaces: allSpaces)
    }
    
    /* returns a mapping of screen uuids and their active space */
    private func parseSpaces(monitors: [[String : Any]]) -> ([ScreenUUID : Space], [Space]) {
        var activeSpaces: [ScreenUUID : Space] = [:]
        var allSpaces: [Space] = []
        var spaceCount = 0
        var counter = 1
        var order = 0
        for m in monitors {
            guard let current = m["Current Space"] as? [String : Any],
                  let spaces = m["Spaces"] as? [[String : Any]],
                  let displayIdentifier = m["Display Identifier"] as? String
            else { continue }
            guard let id64 = current["id64"] as? Int,
                  let uuid = current["uuid"] as? String,
                  let type = current["type"] as? Int,
                  let managedSpaceId = current["ManagedSpaceID"] as? Int
            else { continue }

            allSpaces += parseSpaceList(spaces: spaces, startIndex: counter, activeUUID: uuid, displayIdentifier: displayIdentifier)
            
            let filterFullscreen = spaces.filter{ $0["TileLayoutManager"] as? [String : Any] == nil}
            let target = filterFullscreen.enumerated().first(where: { $1["uuid"] as? String == uuid})
            let number = target == nil ? nil : target!.offset + counter
            
            activeSpaces[displayIdentifier] = Space(id64: id64,
                                                    uuid: uuid,
                                                    type: type,
                                                    managedSpaceId: managedSpaceId,
                                                    number: number,
                                                    order: order,
                                                    displayIdentifier: displayIdentifier,
                                                    isActive: true,
                                                    windowCount: 1)
            spaceCount += spaces.count
            counter += filterFullscreen.count
            order += 1
        }
        return (activeSpaces, allSpaces)
    }
    
    private func parseSpaceList(spaces: [[String : Any]], startIndex: Int, activeUUID: String, displayIdentifier:String = "") -> [Space] {
        var ret: [Space] = []
        var counter: Int = startIndex
        for s in spaces {
            guard let id64 = s["id64"] as? Int,
                  let uuid = s["uuid"] as? String,
                  let type = s["type"] as? Int,
                  let managedSpaceId = s["ManagedSpaceID"] as? Int
                  else { continue }
            let isFullscreen = s["TileLayoutManager"] as? [String : Any] == nil ? false : true
            let number: Int? = isFullscreen ? nil : counter
            let windowCount = number == nil ? 1 : self.windowCount(for: number!)
            ret.append(
                Space(id64: id64,
                      uuid: uuid,
                      type: type,
                      managedSpaceId: managedSpaceId,
                      number: number,
                      order: 0,
                      displayIdentifier: displayIdentifier,
                      isActive: uuid == activeUUID,
                      windowCount: windowCount))
            if !isFullscreen {
                counter += 1
            }
        }
        return ret
    }
    private func windowCount (for desktop: Int) -> Int {
        let countString = chunkwmSend(message: "tiling::query --windows-for-desktop \(desktop)")
        let windows = countString?.split(separator: "\n")
        return windows?.count ?? 0
    }
    
    private func chunkwmSend (message: String) -> String? {
        let chunkPort: UInt16 = 3920
        
        let sockFD = socket(AF_INET, SOCK_STREAM, 0)
        if sockFD == -1 {
            print("Could not create socket!")
            return nil
        }
        
        guard let server = gethostbyname("localhost".cString(using: .utf8)) else {
            print("gethostbyname failed for localhost")
            return nil
        }
        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_port = chunkPort.bigEndian
        memcpy(&serverAddress.sin_addr.s_addr, server.pointee.h_addr_list[0], Int(server.pointee.h_length))
        
        if connect(sockFD, UnsafePointer<sockaddr>(&serverAddress), socklen_t(MemoryLayout<sockaddr>.size)) == -1 {
            print("chunkc: connection failed!")
            return nil
        }
        
        let cMessage = message.cString(using: .utf8)
        let cMessageLength = message.lengthOfBytes(using: .utf8) + 1 // for NULL-termination
        var response = [Int8](repeating: 0, count: Int(BUFSIZ+1))

        if send(sockFD, cMessage, cMessageLength, 0) == -1 {
            print("chunkc: failed to send data!")
        } else {
            let fds = UnsafeMutablePointer<pollfd>.allocate(capacity: 1)
            fds.pointee.fd = sockFD
            fds.pointee.events = Int16(POLLIN)
            fds.pointee.revents = 0
            
            while poll(fds, 2, -1) > 0 {
                let numBytes = recv(sockFD, &response, Int(BUFSIZ), 0)
                if numBytes > 0 {
                    response[numBytes] = 0
                } else {
                    break
                }
            }
            fds.deallocate()
        }
        shutdown(sockFD, SHUT_RDWR)
        close(sockFD)
        return String(cString: &response, encoding: .utf8)
    }
    
}


//
//  UDPBroadcaster.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/4.
//

import Foundation
import SystemConfiguration

class UDPBroadcaster: NSObject {
    private var timer: Timer?
    private let port: UInt16 = 53863
    private var message: String = ""
    
    init(message m: String){
        message = m
    }

    func startBroadcasting(interval: TimeInterval = 0.5) {
        stopBroadcasting()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.sendBroadcast(message: self.message,port: self.port)
        }
    }

    func stopBroadcasting() {
        timer?.invalidate()
        timer = nil
    }

    
    func sendBroadcast(message: String, port: UInt16) {
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard sock >= 0 else {
            print("❌ socket() failed")
            return
        }

        var opt: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &opt, socklen_t(MemoryLayout.size(ofValue: opt)))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("255.255.255.255")

        guard let data = message.data(using: .utf8) else { return }

        data.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.baseAddress else { return }

            withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    let result = sendto(sock, baseAddress, data.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    if result < 0 {
                        perror("sendto")
                    } else {
                        print("✅ 廣播成功")
                    }
                }
            }
        }

        close(sock)
    }
}


class SocketServer {
    
    struct ClientInfo: Hashable {
        let ip: String
        let port: Int
    }
    
    private let port: UInt16
    private var socketFD: Int32 = -1
    private var isRunning = false

    private var connectedClients: [ClientInfo: Int32] = [:]
    private let lock = NSLock()

    init(port: UInt16 = 59620) {
        self.port = port
    }

    func start() {
        DispatchQueue.global(qos: .background).async {
            self.run()
        }
    }
    
    func getConnectedClientsAmout() -> Int {
        connectedClients.count
    }
    

    private func run() {
        if isRunning{print("isRunning");return}
        socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            perror("socket")
            return
        }

        var opt: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout.size(ofValue: opt)))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = self.port.bigEndian
        addr.sin_addr.s_addr = inet_addr("0.0.0.0")

        withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                if bind(socketFD, ptr, socklen_t(MemoryLayout<sockaddr_in>.size)) < 0 {
                    perror("bind")
                    close(socketFD)
                    return
                }
            }
        }

        if listen(socketFD, 5) < 0 {
            perror("listen")
            close(socketFD)
            return
        }

        print("✅ TCP Server listening on port \(port)")
        isRunning = true

        while isRunning {
            var clientAddr = sockaddr_in()
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)

            let clientFD = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(socketFD, $0, &len)
                }
            }

            if clientFD >= 0 {
                let ip = String(cString: inet_ntoa(clientAddr.sin_addr))
                let port = Int(UInt16(bigEndian: clientAddr.sin_port))
                let client = ClientInfo(ip: ip, port: port)

                lock.lock()
                connectedClients[client] = clientFD
                lock.unlock()

                print("🔌 新連線 \(client)，目前共 \(connectedClients.count) 位 client")
                print("現有連線：\(connectedClients)")

                DispatchQueue.global().async {
                    self.handleClient(fd: clientFD, info: client)
                }
            }
        }
    }

    private func handleClient(fd: Int32, info: ClientInfo) {
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = read(fd, &buffer, 1024)
            if count > 0 {
                let msg = String(bytes: buffer[0..<count], encoding: .utf8) ?? "(invalid utf8)"
                print("📩 [\(info)] 收到資料: \(msg)")
            } else {
                break
            }
        }

        lock.lock()
        connectedClients.removeValue(forKey: info)
        lock.unlock()

        print("❌ 離線 \(info)，剩下 \(connectedClients.count) 位 client")
        close(fd)
    }

    func sendResponse(_ message: String, to info: ClientInfo) {
        lock.lock()
        guard let fd = connectedClients[info] else {
            lock.unlock()
            print("⚠️ 找不到 client \(info)")
            return
        }
        lock.unlock()

        message.withCString {
            _ = write(fd, $0, strlen($0))
        }
    }
    
    func broadcast(_ message: String) {
        lock.lock()
        for (_, fd) in connectedClients {
            message.withCString {
                _ = write(fd, $0, strlen($0))
            }
        }
        lock.unlock()
    }

    func stop() {
        isRunning = false
        if socketFD >= 0 {
            close(socketFD)
        }

        lock.lock()
        for (_, fd) in connectedClients {
            close(fd)
        }
        connectedClients.removeAll()
        lock.unlock()
    }
}


func getLocalIPv4Address() -> String? {
    var address: String?

    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee

            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) { // 只找 IPv4
                let name = String(cString: interface.ifa_name)
                
                // 忽略 lo0（loopback）、awdl（AirDrop/Watch）、utun（VPN）
                if name != "lo0" && !name.hasPrefix("awdl") && !name.hasPrefix("utun") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let result = getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    if result == 0 {
                        address = String(cString: hostname)
                        break
                    }
                }
            }

            ptr = interface.ifa_next
        }
        freeifaddrs(ifaddr)
    }

    return address
}

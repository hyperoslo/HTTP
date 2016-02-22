import Foundation

public class Server {

  private var listenSocket: Socket = Socket(fileDescriptor: -1)

  public func start(port: in_port_t = 8080) throws {
    listenSocket = try Socket.socketForPort(port)
    while let clientSocket = try? listenSocket.acceptClient() {
      print(clientSocket)
    }
    NSRunLoop.mainRunLoop().run()
  }
}

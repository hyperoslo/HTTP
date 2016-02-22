import Foundation

public enum SocketError: ErrorType {
  case ClientAcceptFailed
  case FailedBinding
  case FailedListen
}

public class Socket {

  private let fileDescriptor: Int32
  private let lock = NSLock()

  static func socketForPort(port: in_port_t, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
    let fileDescriptor = socket(AF_INET, SOCK_STREAM, 0)

    var address = sockaddr_in()
    address.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
    address.sin_family = sa_family_t(AF_INET)
    address.sin_len = __uint8_t(sizeof(sockaddr_in))
    address.sin_port = Int(OSHostByteOrder()) == OSLittleEndian
      ? _OSSwapInt16(port)
      : port
    address.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)

    var bindAddress = sockaddr()
    memcpy(&bindAddress, &address, Int(sizeof(sockaddr_in)))

    if bind(fileDescriptor, &bindAddress, socklen_t(sizeof(sockaddr_in))) < 0 {
      throw SocketError.FailedBinding
    }

    if listen(fileDescriptor, maxPendingConnection) < 0 {
      throw SocketError.FailedBinding
    }

    return Socket(fileDescriptor: fileDescriptor)
  }

  public init(fileDescriptor: Int32) {
    self.fileDescriptor = fileDescriptor
  }

  public func acceptClient() throws -> Socket {
    var address = sockaddr()
    var len: socklen_t = 0
    let clientSocket = accept(self.fileDescriptor, &address, &len)

    if clientSocket < 0 {
      throw SocketError.ClientAcceptFailed
    }

    var no_sig_pipe: Int32 = 1
    setsockopt(clientSocket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)))

    return Socket(fileDescriptor: clientSocket)
  }
}

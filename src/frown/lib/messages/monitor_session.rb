module Messages
  module MonitorSession

    include EM::Protocols::LineText2
    include Messages::MainLogger

    def post_init
      log_ip_address
      Messages.server = self
    end

    def enque(data)
      send_data(data+"\n")
    end

    def unbind
      log "Server unbound"
    end

    def receive_line(msg)
      data = JSON.parse(msg)
      connection = Messages::Connections[data['id']]
      if ! connection
        if unknown_connections[data['id']].nil?
          log "#{short_id(data['id'])}     No connection for: #{data.inspect}"
          unknown_connections[data['id']] = true
        end
      elsif data['cmd'] == 'frown' && data['data']
        log "#{short_id(data['id'])} --> #{data['data']}"
        connection.send_frown_to_drone(data['data'])
      elsif data['command'] == 'close' # TODO: This doesn't look right
        log "#{short_id(data['id'])}     Handling Close Command (#{data.inspect})"
        connection.close_because("portal request")
      else
        log "#{short_id(data['id'])}     Unknown command from portal: #{data.inspect}"
      end
    rescue StandardError => ex
      log "[ERR] #{ex.inspect}"
      log ex.backtrace
    end

    def short_id(long_id)
      long_id.sub(/-[^-]+-[^-]+-[^-]+$/,'')
    end

    def log_ip_address
      peername = get_peername
      if peername
        port, ip = Socket.unpack_sockaddr_in(peername)
        ip_address = "#{ip}:#{port}"
      else
        ip_address = "UNKNOWN IP ADDRESS"
      end
      log "Server connected from #{ip_address}"
    end

    def unknown_connections
      @unknown_connections ||= {}
    end

    def log(*args)
      Messages.logger.log "[SRV] #{args.join}"
    end
  end
end

local cmd = require("client.command")
local uv = vim.loop

---@class IrcClient
local M = {}

---@class Config
---@field server string
---@field port number
---@field nickname string
---@field username string
---@field realname string
M.config = nil

---@type table
M.tx = nil

---@param command string
M.cmd = function(command)
  M.tx:write(command .. "\r\n")
end

---@param password? string
M.login_to_irc = function(password)
  M.cmd(cmd.nick(M.config.nickname))
  M.cmd(cmd.user(M.config.username, "0", "*", M.config.realname))
  if password then
    M.identify(password)
  end
end

---@param channel string
M.join_channel = function(channel)
  print("Joining channel: " .. channel)
  M.cmd(cmd.join(channel, ""))
end

---@param password string
M.identify = function(password)
  M.cmd("NickServ IDENTIFY" .. M.config.nickname .. password)
end

---@param output function(data: string)
M.connect_to_irc = function(output)
  local ip = M.resolve_hostname(M.config.server)
  M.tx:connect(ip, M.config.port, function(err)
    if err then
      print("Failed to connect to IRC server: " .. err)
    else
      M.login_to_irc()
      print("Connected to IRC server successfully")

      local timer
      local interval = 30 * 1000

      local function send_ping()
        if not M.tx:is_closing() then
          M.cmd(cmd.ping1(M.config.server))
          timer = vim.defer_fn(send_ping, interval)
        else
          vim.clear_fn(timer)
        end
      end
      timer = vim.defer_fn(send_ping, interval)

      M.receive_data(output)
    end
  end)
end

---@param output function(data: string)
M.receive_data = function(output)
  if not M.tx then
    error("Not connected to IRC server", 1)
    return
  end

  M.tx:read_start(function(err, data)
    if err then
      if err.code == "ECONNRESET" then
        print("Connection to IRC server reset by the server")
      else
        print("Error receiving data:", err)
      end
      M.stop_receive_data() -- Stop receiving data
      M.close() -- Close the connection
      return
    end

    if data then
      -- Process the received data
      output(data)
    else
      -- Socket closed
      print("Connection to IRC server closed")
    end
  end)
end

-- Add a function to stop receiving data when needed
M.stop_receive_data = function()
  if not M.tx then
    print("Not connected to IRC server")
    return
  end

  M.tx:read_stop()
end

---@param hostname string
M.resolve_hostname = function(hostname)
  local command = "nslookup " .. hostname
  local handle = io.popen(command)
  assert(handle, "Failed to execute command: " .. command)
  local output = handle:read("*a")
  handle:close()

  -- Parse the output to extract the IP address
  local ip = output:match("Address: ([^\n]+)")

  return ip
end

---@param channel string
---@param message string
M.send_message = function(channel, message)
  if not M.tx then
    print("Not connected to IRC server")
    return
  end
  M.cmd(cmd.privmsg(channel, message))
end

M.close = function()
  M.tx:shutdown()
  M.tx:close()
  M.stop_receive_data()
  M.tx = nil
  M.config = nil
end

M.init = function(server, port, nickname, username, realname)
  if M.tx then
    M.close()
  end
  M.tx = uv.new_tcp()
  M.config = {
    server = server,
    port = port,
    nickname = nickname,
    username = username,
    realname = realname,
  }
  return M
end

return M

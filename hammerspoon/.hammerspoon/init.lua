local home = os.getenv("HOME")

hs.hotkey.bind({"cmd", "alt"}, "R", function()
  local script = home .. "/user/kvoicewalk/bin/read-civilight-clipboard"
  hs.task.new("/bin/bash", nil, {script}):start()
end)

hs.hotkey.bind({"cmd", "alt"}, "C", function()
  local script = home .. "/user/kvoicewalk/bin/stop-civilight"
  hs.task.new("/bin/bash", nil, {script}):start()
end)

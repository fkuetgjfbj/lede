--[[
LuCI - Lua Configuration Partition Expansion
 Copyright (C) 2022  sirpdboy <herboy2008@gmail.com> https://github.com/sirpdboy/partexp
]]--

module("luci.controller.partexp", package.seeall)
require "luci.util"
local name = 'partexp'
function index()
	local e = entry({"admin","system","partexp"},alias("admin", "system", "partexp", "global"),_("Partition Expansion"), 54)
	e.dependent = false
	e.acl_depends = { "luci-app-partexp" }
	entry({"admin", "system", "partexp", "global"}, cbi('partexp/global', {hideapplybtn = true, hidesavebtn = true, hideresetbtn = true}), _('Partition Expansion'), 10).leaf = true 
	entry({"admin", "system", "partexp","partexprun"}, call("partexprun")).leaf = true
	-- entry({"admin", "system", "partexp", "realtime_log"}, call("get_log")) 
end

function get_log()
    local e = {}
    e.running = luci.sys.call("busybox ps -w | grep partexp | grep -v grep >/dev/null") == 0
    e.log = fs.readfile("/etc/partexp/partexp.log") or ""
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function partexprun()
	local uci = luci.model.uci.cursor()
	local keep_config = luci.http.formvalue('keep_config')
	local auto_format = luci.http.formvalue('auto_format')
	local target_function = luci.http.formvalue('target_function')
	local target_disk = luci.http.formvalue('target_disk')
	--uci:delete(name, '@global[0]', global)
	uci:set(name, '@global[0]', 'target_disk', target_disk)
	uci:set(name, '@global[0]', 'target_function', target_function)
	uci:set(name, '@global[0]', 'auto_format', auto_format)
	uci:set(name, '@global[0]', 'keep_config', keep_config)
	uci:commit(name)
	-- e = nixio.exec("/bin/sh", "-c" ,"/etc/init.d/partexp autopart")
	e = luci.sys.exec('/etc/init.d/partexp autopart')

	luci.http.prepare_content('application/json')
	luci.http.write_json(e)
end

function outexec(cmd)
		luci.http.prepare_content("text/plain")
		local util = io.popen(cmd)
		if util then
			while true do
				local ln = util:read("*l")
				if not ln then break end
				luci.http.write(ln)
				luci.http.write("\n")
			end
			util:close()
		end

end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end
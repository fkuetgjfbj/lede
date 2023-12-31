local m, s

m = Map("qbittorrent", translate("qBittorrent"), translate("qBittorrent is a cross-platform free and open-source BitTorrent client. Default username & password: admin / adminadmin"))

m:section(SimpleSection).template  = "qbittorrent_status"

s=m:section(TypedSection, "qbittorrent", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false
s:option(Value, "port", translate("WebUI Port")).rmempty=false
s:option(Value, "profile_dir", translate("Configuration files Path")).rmempty=false


m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/qbittorrent restart >/dev/null 2>&1")
end
return m

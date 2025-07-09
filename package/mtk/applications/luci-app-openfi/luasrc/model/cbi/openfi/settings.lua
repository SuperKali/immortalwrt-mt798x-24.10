local d = require "luci.dispatcher"
local sys  = require "luci.sys"

m = Map("openfi")

s = m:section(NamedSection, "switch", "switch", translate("Switch Settings"))
s.anonymous = true
s.addremove = false

func = s:option(ListValue, "func", translate("Switch configuration"))
func:value("0", translate("Off"))
func:value("1", translate("WAN/LAN Switch"))
func:value("2", translate("Modem Power Switch"))
func:value("3", translate("Led Switch"))

lan = s:option(ListValue, "lan", translate("WAN/LAN Switch"))
lan:depends("func", "0")
lan:depends("func", "2")
lan:depends("func", "3")
lan:value("0", translate("WAN"))
lan:value("1", translate("LAN"))

power = s:option(ListValue, "power", translate("Modem Power Switch"))
power:depends("func", "0")
power:depends("func", "1")
power:depends("func", "3")
power:value("0", translate("Off"))
power:value("1", translate("On"))

led = s:option(ListValue, "led", translate("Led Switch"))
led:depends("func", "0")
led:depends("func", "1")
led:depends("func", "2")
led:value("0", translate("Off"))
led:value("1", translate("On"))

s = m:section(NamedSection, "fan", "fan", translate("Fan Settings"))
s.anonymous = true
s.addremove = false

cpu_high = s:option(Value, "cpu_temp_high", translate("CPU temperature high"))
cpu_high.datatype= "range(20,130)"

cpu_low = s:option(Value, "cpu_temp_low", translate("CPU temperature low"))
cpu_low.datatype= "range(20,130)"

wifi_high = s:option(Value, "wifi_temp_high", translate("WIFI temperature high"))
wifi_high.datatype= "range(20,130)"

wifi_low = s:option(Value, "wifi_temp_low", translate("WIFI temperature low"))
wifi_low.datatype= "range(20,130)"

modem_high = s:option(Value, "modem_temp_high", translate("Modem temperature high"))
modem_high.datatype= "range(20,130)"

modem_low = s:option(Value, "modem_temp_low", translate("Modem temperature low"))
modem_low.datatype= "range(20,130)"

period = s:option(Value, "period", translate("Temperature Period"))
period.datatype= "range(5,300)"

level = s:option(ListValue, "level", translate("Fan Level"))
level:value("0", translate("Slow"))
level:value("1", translate("Middle"))
level:value("2", translate("Fast"))

s = m:section(NamedSection, "reset", "modem", translate("Modem Reset Settings"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "state", translate("Modem reset reverse"))
o.rmempty = false

return m

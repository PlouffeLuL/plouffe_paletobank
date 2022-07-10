Plb = {}
TriggerServerEvent("plouffe_paletobank:sendConfig")

RegisterNetEvent("plouffe_paletobank:getConfig",function(list)
	if not list then
		while true do
			Plb = nil
		end
	else
		for k,v in pairs(list) do
			Plb[k] = v
		end

		Plb:Start()
	end
end)
Auth = exports.plouffe_lib:Get("Auth")
Utils = exports.plouffe_lib:Get("Utils")
Callback = exports.plouffe_lib:Get("Callback")

Server = {
	ready = false,
}

Plb = {}

Plb.Utils = {
	ped = 0,
	pedCoords = vector3(0,0,0),
  lockpickAmount = 17,
  hackingDelay = 1000 * 10,
  readyDelay = math.random(1000 * 60 * 60, 1000 * 60 * 60 * 2),
  doorDelay = 1000 * 60 * 10
}

Plb.Zones = {
  paleto_bank = {
		name = "paleto_bank",
    isZone = true,
    zMax = 37.2,
    zMin = 29.0,
    coords = {
      vector3(-123.50521087646, 6472.4423828125, 31.808837890625),
      vector3(-115.15476226807, 6480.71484375, 31.808837890625),
      vector3(-113.40524291992, 6479.3232421875, 31.808837890625),
      vector3(-107.75926208496, 6485.0224609375, 31.808837890625),
      vector3(-88.75464630127, 6466.2260742188, 31.808837890625),
      vector3(-102.62382507324, 6451.5463867188, 31.808837890625)
    },
    zoneMap = {
      inEvent = "plouffe_paletobank:inZone",
      outEvent = "plouffe_paletobank:exitZone"
    }
  },

  paleto_bank_hack_office = {
    name = "paleto_bank_hack_office",
    isZone = true,
    label = "Connection",
    distance = 0.5,
    params = {fnc = "TryHack", zone = "office"},
    coords = vector3(-105.2568359375, 6479.7719726563, 31.634143829346),
    keyMap = {
      key = "E", 
      event = "plouffe_paletobank:onZone"
    }
  },

  paleto_bank_hack_security = {
    name = "paleto_bank_hack_security",
    isZone = true,
    label = "Connection",
    distance = 0.5,
    params = {fnc = "TryHack", zone = "security"},
    coords = vector3(-92.200340270996, 6465.3618164063, 31.634141921997),
    keyMap = {
      key = "E", 
      event = "plouffe_paletobank:onZone"
    }
  },
}

Plb.Doords = {
  "paleto_bank_office_door",
  "paleto_bank_security",
  "paleto_bank_to_rear_entry",
  "paleto_bank_minidoor",
  "paleto_bank_behind_desk",
  "paleto_bank_side_entry",
  "paleto_bank_rear_entry"
}

Plb.HackingZone = {
  office = {
    coords = vector3(-105.25743103027, 6479.7719726563, 31.634143829346), 
    maxDst = 0.5,
  },

  security = {
    coords = vector3(-92.203048706055, 6465.3525390625, 31.634145736694), 
    maxDst = 0.5,
  }
}

Plb.Trolley = {
  cash = {trolley = "hei_prop_hei_cash_trolly_01", prop = "hei_prop_heist_cash_pile", empty = "hei_prop_hei_cash_trolly_03"},
  gold = {trolley = "ch_prop_gold_trolly_01a", prop = "ch_prop_gold_bar_01a", empty = "hei_prop_hei_cash_trolly_03"},
  diamond = {trolley = "ch_prop_diamond_trolly_01a", prop = "ch_prop_vault_dimaondbox_01a", empty = "hei_prop_hei_cash_trolly_03"}
}

Plb.TrolleySpawns = {
  {
    coords = vector3(-97.72991607666, 6463.8230859373, 30.658917236328),
    rotation = vector3(0.0, -0.0, 135.470000000001)
  },

  {
    coords = vector3(-96.52491607666, 6462.5005859375, 30.658917236328),
    rotation = vector3(0.0, -0.0, 135.0)
  },

  {
    coords = vector3(-96.924831542969, 6460.015234375, 30.658926773071),
    rotation = vector3(0.0, -0.0, 45.64)
  },

  {
    coords = vector3(-100.85595703125, 6461.2131835938, 30.658894348145),
    rotation = vector3(0.0, -0.0, -45.7)
  }
}

fhotkey = {}
fhotkey.current_mod = SMODS.current_mod
local config = fhotkey.current_mod.config

local function create_keybind_box(module, description)
  return {
    n = G.UIT.R,
    config = { padding = 0.2, align = "cm" },
    nodes = {
      {
        n = G.UIT.C,
        config = { align = "cl" },
        nodes = {
          {
            n = G.UIT.T,
            config = { text = description, colour = G.C.WHITE, scale = 0.35, align = "cm" },
          }
        }
      }
      ,
      {
        n = G.UIT.C,
        config = { padding = 0.05, align = "cm" },
        nodes = {


          UIBox_button({
            label = { module.key1 or "None" },
            col = true,
            colour = G.C.Mult,
            scale = 0.35,
            --minw = 2.75,
            minh = 0.45,
            ref_table = {
              configs = module,
              key = "key1"
            },
            button = "fhotkey_key_change",
          })
          ,

          UIBox_button({
            label = { module.key2 or "None" },
            col = true,
            colour = G.C.Mult,
            scale = 0.35,
            --minw = 2.75,
            minh = 0.45,
            ref_table = {
              configs = module,
              key = "key2"
            },
            button = "fhotkey_key_change",
          })
        },
      },
    }
  }
end

fhotkey.current_mod.config_tab = function()
  return {
    n = G.UIT.ROOT,
    config = {
      align = "cm",
    },
    nodes = {
      {
        n = G.UIT.C,
        config = { padding = 0.05 },
        nodes = {
          create_keybind_box(config.flush_keys, "Select flushes"),
          create_keybind_box(config.oak_keys, "5-4-3 of a kinds"),
          create_keybind_box(config.str_keys, "Straights"),
          create_keybind_box(config.invert_keys, "Invert selection"),
          create_keybind_box(config.play_hand_keys, "Play Hand"),
          create_keybind_box(config.discard_hand_keys, "Discard Hand"),
        }
      }
    }
  }
end
local is_catching_key = false

local function get_visible_rank(card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.facing == 'back' then return "stone" end
  return string.format(card.base.id)
end

local function get_visible_suit(card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.ability.name == "Wild Card" and not card.debuff then return "wild" end
  if card.facing == "back" then return "stone" end
  return card.base.suit
end

local function ranksuit(card)
  return get_visible_rank(card)..get_visible_suit(card)
end

local function calculate_importance(card, is_for_play)
  -- im putting this table for fine tuning. change the numbers if you want
  local importances = {
    play = {
      seal = {
        Gold = 50,
        Blue = -10,
        Red = 50,
        Purple = -10
      },
      edition = {
        holo = 70,
        foil = 60,
        polychrome = 75
      },
      ability = {
        Steel = -20,
        Glass = 25,
        Wild = 15,
        Bonus = 25,
        Mult = 25,
        Stone = 15,
        Lucky = 25,
        Gold = -10
      }
    },
    discard = {
      seal = {
        Gold = 50,
        Blue = -10,
        Red = 50,
        Purple = -50
      },
      edition = {
        holo = 70,
        foil = 60,
        polychrome = 75
      },
      ability = {
        Steel = 30,
        Glass = 25,
        Wild = 15,
        Bonus = 25,
        Mult = 25,
        Stone = 15,
        Lucky = 25,
        Gold = 15
      }
    }
  }
  -- we can maybe implement the joker interactions
  local res = 0
  if card.flipped then return -20 end
  if card.debuff then return -5 end
  if is_for_play then
    if card.seal then
      res = res + (importances.play.seal[card.seal] or 0)
    end
    if card.edition then
      if card.edition.holo then
        res = res + importances.play.edition.holo
      elseif card.edition.foil then
        res = res + importances.play.edition.foil
      elseif card.edition.polychrome then
        res = res + importances.play.edition.polychrome
      else
        res = res + 0
      end
    end
    if card.ability then
      local effect = string.gsub(card.ability.name, " Card", "")
      res = res + (importances.play.ability[effect] or 0)
    end
  else
    if card.seal then
      res = res + (importances.discard.seal[card.seal] or 0)
    end
    if card.edition then
      if card.edition.holo then
        res = res + importances.discard.edition.holo
      elseif card.edition.foil then
        res = res + importances.discard.edition.foil
      elseif card.edition.polychrome then
        res = res + importances.discard.edition.polychrome
      else
        res = res + 0
      end
    end
    if card.ability then
      local effect = string.gsub(card.ability.name, " Card", "")
      res = res + (importances.discard.ability[effect] or 0)
    end
  end
  res = res + card.base.id
  return res
end

local function is_subset(subset, superset, hasher)
  for k, v in pairs(subset) do
    local found = false
    for k2, v2 in pairs(superset) do
      found = found or (hasher(v) == hasher(v2))
    end
    if not found then
      return false
    end
  end
  return true
end

local function merge(arr1, arr2)
  local res = {}
  for k, v in pairs(arr1) do
    table.insert(res, v)
  end
  for k, v in pairs(arr2) do
    table.insert(res, v)
  end
  return res
end

local function filter(arr, f)
  local res = {}
  for i, v in pairs(arr) do
    if (f(v)) then
      table.insert(res, v)
    end
  end
  return res
end

local function indexOf(arr, f)
  for key, value in pairs(arr) do
    if f(value) then return key end
  end
  return -1
end

local function take(arr, n)
  local res = {}
  for i = 1, n, 1 do
    if not arr[i] then return res end
    table.insert(res, arr[i])
  end
  return res
end

local function first(arr)
  for key, value in pairs(arr) do
    return value
  end
  return nil
end

local function map_f(arr, f)
  local res = {}
  for k, v in pairs(arr) do
    table.insert(res, f(v))
  end
  return res
end

local function hand_importance(hand)
  res = 0
  for k, v in pairs(hand) do
    res = res + calculate_importance(v, true)
  end
  return res
end

local function possible_straights(cards)
  local ranked_cards = filter(cards, function(c) return get_visible_rank(c) ~= "stone" end)
  print(string.format(#ranked_cards))
  local cards_by_rank = {}
  for _, card in pairs(ranked_cards) do
    local rank = get_visible_rank(card)
    if not cards_by_rank[rank] then
      cards_by_rank[rank] = card
    else
      -- only hold the best card in each rank
      if calculate_importance(card, true) > calculate_importance(cards_by_rank[rank]) then
        cards_by_rank[rank] = card
      end
    end
  end
  -- we save
  -- 2,3,4,5 consecutive card runs
  -- ++-++ pattern

  local fives = {}
  local fours = {}
  local threes = {}
  local twos = {}
  local two_two = {}
  local current_run = {}
  local previous_run = {}
  if cards_by_rank[14] then table.insert(current_run, cards_by_rank[14]) end
  for i = 2, 15, 1 do
    local curr_rank = string.format(i)
    if cards_by_rank[curr_rank] then
      table.insert(current_run, cards_by_rank[curr_rank])
    else
      if #current_run >= 5 then
        local hand_to_add = {}
        for j = #current_run, #current_run - 5, -1 do
          table.insert(hand_to_add, current_run[j])
        end
        table.insert(fives, hand_to_add)
        current_run = {}
        previous_run = {}
      elseif #current_run == 4 then

        table.insert(fours, current_run)
        current_run = {}
        previous_run = {}
      elseif #current_run == 3 then
        table.insert(threes, current_run)
        current_run = {}
        previous_run = {}
      elseif #current_run == 2 then
        if #previous_run == 2 then
          table.insert(two_two, merge(current_run, previous_run))
        end
        table.insert(twos, current_run)
        previous_run = current_run
        current_run = {}
      else
        current_run = {}
        previous_run = {}
      end
    end
  end
  local sorter = function(x, y) return hand_importance(x) > hand_importance(y) end
  table.sort(fives, sorter)
  table.sort(fours, sorter)
  table.sort(threes, sorter)
  table.sort(two_two, sorter)
  table.sort(twos, sorter)
  local res = {}
  res = merge(res, fives)
  res = merge(res, fours)
  res = merge(res, two_two)
  res = merge(res, threes)
  res = merge(res, twos)
  return res
end

local function possible_flushes(cards)
  local dictionary = {}
  local wilds = {}
  for i, v in pairs(cards) do
    local suit = get_visible_suit(v)
    if suit == "wild" then
      table.insert(wilds, v)
    else
      if not dictionary[suit] then
        dictionary[suit] = {}
      end
      table.insert(dictionary[suit], v)
    end
  end
  table.sort(wilds, function(x, y) return calculate_importance(x, true) > calculate_importance(y, true) end)

  local res = {}
  for k, v in pairs(dictionary) do
    table.sort(v, function(x, y) return calculate_importance(x, true) > calculate_importance(y, true) end)
    local flush_hand = take(v, 5)
    if #flush_hand < 5 and #wilds > 0 then
      flush_hand = merge(flush_hand, take(wilds, 5-#flush_hand))
    end
    table.insert(res, flush_hand)
  end
  table.sort(res, function(x, y)
    return ((#x == #y) and (hand_importance(x) > hand_importance(y)))
        or #x > #y
  end)
  return res
end

local function next_best_hand(possible_hands, curr_hand, hasher)
  print("#Hands, #Cards_in_hand:")
  print(string.format(#possible_hands).."|"..string.format(#curr_hand))
  if #possible_hands == 1 then return possible_hands[1] end
  if #possible_hands == 0 then return {} end
  if #curr_hand == 0 then return possible_hands[1] end

  -- if curr_hand is found in possible hands, select the next one
  -- otherwise, if only 1 card is selected, select best hand containing it
  -- otherwise, select best hand containing it (but is slower)
  local best_superset = false
  for i = 1, #possible_hands do
    if is_subset(curr_hand, possible_hands[i], hasher) then
      if #curr_hand == #possible_hands[i] then
        if i == #possible_hands then
          return possible_hands[1]
        else
          return possible_hands[i+1]
        end
      elseif #curr_hand == 1 then
        return possible_hands[i]
      else
        if not best_superset then
          best_superset = possible_hands[i]
        end
      end
    end
  end
  if best_superset then
    return best_superset
  end
  return possible_hands[1]
end

local function best_ofakinds(cards)
  local fives, fours, trips, twos = {}, {}, {}, {}
  local rank_counts = {}
  for i, card in pairs(cards) do
    local rank = get_visible_rank(card)
    if not (rank == "stone") then
      if not rank_counts[rank] then
        rank_counts[rank] = {}
      end
      table.insert(rank_counts[rank], card)
    end
  end
  for k, v in pairs(rank_counts) do
    table.sort(v, function(x, y) return calculate_importance(x, true) > calculate_importance(y, true) end)
    if #v >= 5 then
      table.insert(fives, take(v, 5))
    elseif #v == 4 then
      table.insert(fours, v)
    elseif #v == 3 then
      table.insert(trips, v)
    elseif #v == 2 then
      table.insert(twos, v)
    end
  end
  local union = {}
  local full_houses = {}
  local two_pairs = {}
  union = merge(union, fives)
  union = merge(union, fours)
  union = merge(union, trips)

  for i = 1, (#union - 1) do
    for j = i + 1, #union do
      table.insert(full_houses, merge(
        take(union[i], 3),
        take(union[j], 2)
      ))
      table.insert(full_houses, merge(
        take(union[i], 2),
        take(union[j], 3)
      ))
    end
  end
  for i = 1, #union do
    for k, v in pairs(twos) do
      table.insert(full_houses, merge(v, take(union[i], 3)))
    end
  end
  for i = 1, (#twos - 1) do
    for j = i + 1, #twos do
      table.insert(two_pairs, merge(twos[i], twos[j]))
    end
  end
  table.sort(fives, function(x, y) return hand_importance(x) > hand_importance(y) end)
  table.sort(fours, function(x, y) return hand_importance(x) > hand_importance(y) end)
  table.sort(trips, function(x, y) return hand_importance(x) > hand_importance(y) end)
  table.sort(full_houses, function(x, y) return hand_importance(x) > hand_importance(y) end)
  table.sort(two_pairs, function(x, y) return hand_importance(x) > hand_importance(y) end)
  table.sort(twos, function(x, y) return hand_importance(x) > hand_importance(y) end)
  local res = {}
  res = merge(res, fives)
  res = merge(res, fours)
  res = merge(res, full_houses)
  res = merge(res, trips)
  res = merge(res, two_pairs)
  res = merge(res, twos)
  return res
end

local function select_hand(cards)
  G.hand:unhighlight_all()
  for k, v in pairs(cards) do
    if indexOf(G.hand.highlighted, function(x) return x == v end) == -1 then
      G.hand:add_to_highlighted(v, true)
    end
  end
  if next(cards) then
    play_sound("cardSlide1")
  else
    play_sound("cancel")
  end
end

local function invert_selection()
  local unselected = filter(G.hand.cards, function(x)
    return -1 == indexOf(G.hand.highlighted, function(y) return y == x end)
  end)
  table.sort(unselected, function(x, y) return calculate_importance(x, false) < calculate_importance(y, false) end)
  select_hand(take(unselected, 5))
end

local function select_flush()
  local possible_hands = possible_flushes(G.hand.cards)
  local wildless_hand = filter(G.hand.highlighted, function (c) return get_visible_suit(c) ~= "wild" end)
  select_hand(next_best_hand(possible_hands, wildless_hand, get_visible_suit))
end

local function bind_new_key(key, button)
  local button_text = button.children[1].children[1]
  button_text.config.text_drawable = nil
  button_text.config.text = key
  button_text:update_text()
  button.config.ref_table.configs[button.config.ref_table.key] = key
end

local function handle_hotkeys(key, handle_ref)
  if G.CONTROLLER and G.CONTROLLER.text_input_hook then
    return handle_ref()
  end
  key = key:sub(1, 1):upper() .. key:sub(2)
  if is_catching_key then
    if key == "Mouse1" or key == "Escape" then
    else
      bind_new_key(key, is_catching_key)
    end
    is_catching_key.config.colour = G.C.MULT
    is_catching_key.children[1].children[1].UIBox:recalculate()
    is_catching_key = false
    return
  end
  if G.STATE == G.STATES.SELECTING_HAND then
    local keycomp = function(x) return x == key end
    if not (indexOf(config.flush_keys, keycomp) == -1) then
      select_flush()
    elseif not (indexOf(config.oak_keys, keycomp) == -1) then
      local best_hands = best_ofakinds(G.hand.cards)
      select_hand(next_best_hand(best_hands, G.hand.highlighted, get_visible_rank))
    elseif not (indexOf(config.str_keys, keycomp) == -1) then
      local best_hands = possible_straights(G.hand.cards)
      select_hand(next_best_hand(best_hands, G.hand.highlighted, get_visible_rank))
    elseif not (indexOf(config.invert_keys, keycomp) == -1) then
      invert_selection()
    elseif not (indexOf(config.play_hand_keys, keycomp) == -1) then
      if #G.hand.highlighted > 0 and (not G.GAME.blind.block_play) and #G.hand.highlighted <= 5 then
        G.FUNCS.play_cards_from_highlighted()
      else
        play_sound("cancel")
      end
    elseif not (indexOf(config.discard_hand_keys, keycomp) == -1) then
      if (G.GAME.current_round.discards_left > 0) and (#G.hand.highlighted > 0) then
        G.FUNCS.discard_cards_from_highlighted()
      else
        play_sound("cancel")
      end
    else
      handle_ref()
    end
  else
    handle_ref()
  end
end

function G.FUNCS.fhotkey_key_change(button)
  if is_catching_key then return end
  button.config.text = ""
  button.config.colour = G.C.MONEY
  is_catching_key = button
end

local wheelmovedref = love.wheelmoved or function() end
function love.wheelmoved(x, y)
  local res_key = ""
  if y > 0 then
    res_key = "Scroll Up"
  else
    res_key = "Scroll Down"
  end
  handle_hotkeys(res_key, function() wheelmovedref(x, y) end)
end

local mouseref = love.mousepressed
function love.mousepressed(x, y, button, istouch, presses)
  pressed_button = string.format("mouse%i", button)
  handle_hotkeys(pressed_button, function() mouseref(x, y, button, istouch, presses) end)
end

local keyupdate_ref = Controller.key_press_update
function Controller:key_press_update(key, dt)
  handle_hotkeys(key, function() keyupdate_ref(self, key, dt) end)
end

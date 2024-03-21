--- STEAMODDED HEADER
--- MOD_NAME: Flush Hotkeys
--- MOD_ID: FlushHotkeys
--- MOD_AUTHOR: [Agora]
--- MOD_DESCRIPTION: Hotkeys for flushes, pairs, inverting selection.

----------------------------------------------
------------MOD CODE -------------------------
local flush_hotkey = "f"
local pair_hotkey = "d"
local invert_selection_hotkey = "s"

-- 1, 2, 3 are LMB, RMB, and middle mouse button respectively. If you have additional mouse buttons try setting
-- the number to 4, 5...
local mouse_flush_hotkey = 400
local mouse_pair_hotkey = 400
local mouse_invert_hotkey = 3

local keyupdate_ref = Controller.key_press_update
function Controller.key_press_update(self, key, dt)
  keyupdate_ref(self, key, dt)

  if G.STATE == G.STATES.SELECTING_HAND then
    if key == flush_hotkey then
      select_with_property(get_visible_suit)
    end
    if key == pair_hotkey then
      local best_hands = best_ofakinds(G.hand.cards)
      select_hand(next_best_oak(best_hands, G.hand.highlighted))
    end
    if key == invert_selection_hotkey then
      invert_selection()
    end
  end
end

local mouseref = love.mousepressed
function love.mousepressed(x, y, button, istouch, presses)
  mouseref(x, y, button, istouch, presses)
  if G.STATE == G.STATES.SELECTING_HAND then
    if button == mouse_flush_hotkey then
      select_with_property(get_visible_suit)
    elseif button == mouse_pair_hotkey then
      local best_hands = best_ofakinds(G.hand.cards)
      select_hand(next_best_oak(best_hands, G.hand.highlighted))
      
    elseif button == mouse_invert_hotkey then
      invert_selection()
    end
  end
end

--local wheelmovedref = love.wheelmoved
function love.wheelmoved(x, y)
  --wheelmovedref(x,y)
  if G.STATE == G.STATES.SELECTING_HAND then
    if y > 0 then
      local best_hands = best_ofakinds(G.hand.cards)
      select_hand(next_best_oak(best_hands, G.hand.highlighted))
    elseif y < 0 then
      select_with_property(get_visible_suit)
    end
  end
end


function next_best_oak(possible_hands, curr_hand)
  if #possible_hands == 1 then
    return possible_hands[1]
  end
  if #possible_hands == 0 then
    return {}
  end
  for i = 1, (#possible_hands - 1) do
    if are_ranks_same(possible_hands[i], curr_hand) then
      return possible_hands[i + 1]
    end
  end
  return possible_hands[1]
end

function best_ofakinds(cards)
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
  local res = {}
  for i, v in pairs(fives) do
    table.insert(res, v)
  end
  for i, v in pairs(fours) do
    table.insert(res, v)
  end
  for i, v in pairs(trips) do
    for i2, v2 in pairs(twos) do
      table.insert(res, merge(v, v2))
    end
    table.insert(res, v)
  end

  for i = 1, (#twos-1) do
    for j = i+1, #twos do
      table.insert(res, merge(twos[i], twos[j]))
    end
  end
  for i, v in pairs(twos) do
    table.insert(res, v)
  end
  return res
end

function invert_selection()
  local unselected = filter(G.hand.cards, function(x)
    return -1 == indexOf(G.hand.highlighted,
      function(y) return y == x end)
  end)
  table.sort(unselected, function(x, y) return calculate_importance(x) < calculate_importance(y) end)
  select_hand(take(unselected, 5))
end

function select_with_property(property_func)
  local possible_hands = possible_hands(G.hand.cards, property_func)
  if not next(possible_hands) then return end
  if #G.hand.highlighted == 0 then
    select_hand(possible_hands[1])
  elseif #filter(G.hand.highlighted, function(s) return property_func(s) == property_func(G.hand.highlighted[1]) end) == #G.hand.highlighted then
    local curr_ind = indexOf(possible_hands,
      function(k) return property_func(k[1]) == property_func(G.hand.highlighted[1]) end)
    if #G.hand.highlighted == #possible_hands[curr_ind] then
      if curr_ind == #possible_hands then
        select_hand(possible_hands[1])
      else
        select_hand(possible_hands[curr_ind + 1])
      end
    else
      select_hand(possible_hands[curr_ind])
    end
  else
    select_hand(possible_hands[1])
  end
end

function merge(arr1, arr2)
  local res = {}
  for k, v in pairs(arr1) do
    table.insert(res, v)
  end
  for k, v in pairs(arr2) do
    table.insert(res, v)
  end
  return res
end

function filter(arr, f)
  local res = {}
  for i, v in pairs(arr) do
    if (f(v)) then
      table.insert(res, v)
    end
  end
  return res
end

function indexOf(arr, f)
  for key, value in ipairs(arr) do
    if f(value) then return key end
  end
  return -1
end

function take(arr, n)
  local res = {}
  for i = 1, n, 1 do
    if not arr[i] then return res end
    table.insert(res, arr[i])
  end
  return res
end

function are_ranks_same(hand1, hand2)
  local h1_ranks = map_f(hand1, get_visible_rank)
  local h2_ranks = map_f(hand2, get_visible_rank)
  local h1_rank_counts = {}
  for i, v in ipairs(h1_ranks) do
    if not h1_rank_counts[v] then
      h1_rank_counts[v] = 0
    end
    h1_rank_counts[v] = h1_rank_counts[v] + 1
  end
  local h2_rank_counts = {}
  for i, v in ipairs(h2_ranks) do
    if not h2_rank_counts[v] then
      h2_rank_counts[v] = 0
    end
    h2_rank_counts[v] = h2_rank_counts[v] + 1
  end
  for k, v in pairs(h1_rank_counts) do
    if not h2_rank_counts[k] then return false end
    if not (h2_rank_counts[k] == v) then return false end
  end
  -- this is a bad solution but this part is not computation intensive anyways
  for k, v in pairs(h2_rank_counts) do
    if not h1_rank_counts[k] then return false end
    if not (h1_rank_counts[k] == v) then return false end
  end
  return true
end

function map_f(arr, f)
  local res = {}
  for k, v in pairs(arr) do
    table.insert(res, f(v))
  end
  return res
end

function possible_hands(cards, prop_selector)
  local dictionary = {}
  for i, v in pairs(cards) do
    if not dictionary[prop_selector(v)] then
      dictionary[prop_selector(v)] = {}
    end
  end
  for k, v in pairs(cards) do
    if #dictionary[prop_selector(v)] < 5 then
      table.insert(dictionary[prop_selector(v)], v)
    end
  end
  local res = {}
  for k, v in pairs(dictionary) do
    table.insert(res, v)
  end
  table.sort(res, function(x, y) return #x > #y end)
  return res
end

function select_hand(cards)
  G.hand:unhighlight_all()
  for k, v in pairs(cards) do
    G.hand:add_to_highlighted(v, true)
  end
  play_sound('cardSlide1')
end

function get_visible_suit(card)
  if card.ability.effect == 'Stone Card' then return 'stone' end
  -- applying wild cards to every flush needs hardcoding so im skipping it
  if card.ability.name == "Wild Card" and not card.debuff then return 'stone' end
  if card.facing == 'back' then return 'stone' end
  return card.base.suit
end

function get_visible_rank(card)
  if card.ability.effect == 'Stone Card' then return 'stone' end
  if card.facing == 'back' then return 'stone' end
  return card.base.id -- return card.base.id seems better
end

function calculate_importance(card)
  local res = 0
  if card.flipped then return -20 end
  if card.seal and not card.debuff then
    if card.seal == "Gold" then
      res = res + 50
    elseif card.seal == "Blue" then
      res = res + 10 -- we hate blue amirite
    elseif card.seal == "Red" then
      res = res + 50
    elseif card.seal == "Purple" then
      res = res - 50
    end
  end

  if card.edition and not card.debuff then
    res = res + (card.edition.holo and 70 or 0) + (card.edition.foil and 60 or 0) +
        (card.edition.polychrome and 75 or 0)
    -- "Gold Card", "Glass Card", "Wild Card", "Bonus", "Mult", "Steel Card", "Stone Card", "Lucky Card"
  end
  if card.ability and not card.debuff then
    if card.ability.name == "Steel Card" then
      res = res + 20
    elseif card.ability.name == "Glass Card" then
      res = res + 20
    elseif card.ability.name == "Wild Card" then
      res = res + 15
    elseif card.ability.name == "Bonus" then
      res = res + 20
    elseif card.ability.name == "Mult" then
      res = res + 20
    elseif card.ability.name == "Stone Card" then
      res = res + 20
    elseif card.ability.name == "Lucky Card" then
      res = res + 20
    end
  end
  res = res + card.base.id
  return res
end

----------------------------------------------
------------MOD CODE END----------------------

---@diagnostic disable: unused-local

fhotkey = fhotkey or {}
fhotkey.current_mod = SMODS.current_mod
local config = fhotkey.current_mod.config

local F = {}
fhotkey.FUNCS = F

-- which hand is selected first, reorder if you want
local hand_order = {
  "5oak",
  "4oak",
  "fullhouse",
  "5flush",
  "5str",
  "2pair",
  "4flush",
  "3oak",
  "4str",
  "str2pair", -- "e.g having 89JQ"
  "3flush",
  "3str",
  "2oak",
  "2flush",
  "2str",
}
local hand_priority = {}
for i, v in ipairs(hand_order) do
  hand_priority[v] = #hand_order - i
end

F.create_keybind_box = function (module, description)
  return {
    n = G.UIT.R,
    config = { padding = 0.2},
    nodes = {
      {
        n = G.UIT.C,
        config = { align = "cl", maxw=3 },
        nodes = {
          {
            n = G.UIT.T,
            config = { text = description, colour = G.C.WHITE, scale = 0.35, align = "cl" },
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
            align = "cm",
            col = true,
            colour = G.C.Mult,
            scale = 0.35,
            maxw=3,
            minh = 0.45,
            ref_table = {
              configs = module,
              key = "key1"
            },
            button = "fhotkey_key_change",
          })
        },
      },
      {
        n = G.UIT.C,
        config = { padding = 0.05, align = "cr" },
        nodes = {

          UIBox_button({
            label = { module.key2 or "None" },
            align = "cr",
            col = true,
            colour = G.C.Mult,
            scale = 0.35,
            maxw=3,
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

F.create_keybind_toggle = function (module, field, description)
  return {
    n = G.UIT.R,
    config = { padding = 0.2, align = "cm"},
    nodes = {
      {
        n = G.UIT.C,
        config = { align = "cl", minw=2, },
        nodes = {
          {
            n = G.UIT.T,
            config = { text = description, colour = G.C.WHITE, scale = 0.35, align = "cl" },
          }
        }
      }
      ,
      {
        n = G.UIT.C,
        config = { align = "cm", padding = 0.05, minw=2, },
        nodes = {
          {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {

              create_toggle({
                label = "",
                w = 0,
                align = "cm",
                ref_table = module.key1conf,
                ref_value = field,
              }),
            }
          }
        }
      },
      {
        n = G.UIT.C,
        config = { align = "cr", padding = 0.05, minw=2, },
        nodes = { {
          n = G.UIT.R,
          config = { align = "cm" },
          nodes = {

            create_toggle({
              label = "",
              w = 0,
              align = "cr",
              ref_table = module.key2conf,
              ref_value = field,
            })

          }
        } }
      }
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
        config = { padding = 0.05, align = "cm" },
        nodes = {
          F.create_keybind_box(config.best_hand_keys, "Select best hands"),
          F.create_keybind_toggle(config.best_hand_keys, "accept_flush", "Include flushes"),
          F.create_keybind_toggle(config.best_hand_keys, "accept_oak", "Include 5-4-3 pairs"),
          F.create_keybind_toggle(config.best_hand_keys, "accept_str", "Include straights"),
          F.create_keybind_box(config.invert_keys, "Invert selection"),
          F.create_keybind_box(config.play_hand_keys, "Play Hand"),
          F.create_keybind_box(config.discard_hand_keys, "Discard Hand"),
        }
      }
    }
  }
end
local is_catching_key = false

F.get_visible_rank = function (card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.facing == 'back' then return "stone" end
  return string.format(card.base.id)
end

F.get_visible_suit = function (card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.ability.name == "Wild Card" and not card.debuff then return "wild" end
  if card.facing == "back" then return "stone" end
  return card.base.suit
end

F.ranksuit = function (card)
  return F.get_visible_rank(card) .. F.get_visible_suit(card)
end

F.calculate_importance = function (card, is_for_play)
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

F.hand_importance = function (hand)
  local res = 0
  for k, v in pairs(hand) do
    res = res + F.calculate_importance(v, true)
  end
  return res
end

F.is_better_hand = function (hand1, hand2)
  if hand1.hand_type ~= hand2.hand_type then
    return hand_priority[hand1.hand_type] > hand_priority[hand2.hand_type]
  end
  return F.hand_importance(hand1.hand) > F.hand_importance(hand2.hand)
end

F.is_subset = function (subset, superset, hasher)
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

F.merge = function (arr1, arr2)
  local res = {}
  for k, v in pairs(arr1) do
    table.insert(res, v)
  end
  for k, v in pairs(arr2) do
    table.insert(res, v)
  end
  return res
end

F.filter = function (arr, f)
  local res = {}
  for i, v in pairs(arr) do
    if (f(v)) then
      table.insert(res, v)
    end
  end
  return res
end

F.indexOf = function (arr, f)
  for key, value in pairs(arr) do
    if f(value) then return key end
  end
  return -1
end

F.take = function (arr, n)
  local res = {}
  for i = 1, n, 1 do
    if not arr[i] then return res end
    table.insert(res, arr[i])
  end
  return res
end

F.first = function (arr)
  for key, value in pairs(arr) do
    return value
  end
  return nil
end

F.map_f = function (arr, f)
  local res = {}
  for k, v in pairs(arr) do
    table.insert(res, f(v))
  end
  return res
end

F.hands_to_named = function (hands, name)
  local res = {}
  for k, v in pairs(hands) do
    table.insert(res, {
      hand = v,
      hand_type = name
    })
  end
  return res
end

F.possible_straights = function (cards)
  local ranked_cards = F.filter(cards, function(c) return F.get_visible_rank(c) ~= "stone" end)
  local cards_by_rank = {}
  for _, card in pairs(ranked_cards) do
    local rank = F.get_visible_rank(card)
    if not cards_by_rank[rank] then
      cards_by_rank[rank] = card
    else
      -- only hold the best card in each rank
      if F.calculate_importance(card, true) > F.calculate_importance(cards_by_rank[rank]) then
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
  if cards_by_rank["14"] then table.insert(current_run, cards_by_rank["14"]) end
  for i = 2, 15, 1 do
    local curr_rank = string.format(i)
    if cards_by_rank[curr_rank] then
      table.insert(current_run, cards_by_rank[curr_rank])
    else
      if #current_run >= 5 then
        local hand_to_add = {}
        for j = #current_run, #current_run - 4, -1 do
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
          table.insert(two_two, F.merge(current_run, previous_run))
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
  local res = {}
  res = F.merge(res, F.hands_to_named(fives, "5str"))
  res = F.merge(res, F.hands_to_named(fours, "4str"))
  res = F.merge(res, F.hands_to_named(two_two, "str2pair"))
  res = F.merge(res, F.hands_to_named(threes, "3str"))
  res = F.merge(res, F.hands_to_named(twos, "2str"))
  return res
end

F.possible_flushes = function (cards)
  local dictionary = {}
  local wilds = {}
  for i, v in pairs(cards) do
    local suit = F.get_visible_suit(v)
    if suit == "wild" then
      table.insert(wilds, v)
    else
      if not dictionary[suit] then
        dictionary[suit] = {}
      end
      table.insert(dictionary[suit], v)
    end
  end
  table.sort(wilds, function(x, y) return F.calculate_importance(x, true) > F.calculate_importance(y, true) end)

  local res = {}
  for k, v in pairs(dictionary) do
    table.sort(v, function(x, y) return F.calculate_importance(x, true) > F.calculate_importance(y, true) end)
    local flush_hand = F.take(v, 5)
    if #flush_hand < 5 and #wilds > 0 then
      flush_hand = F.merge(flush_hand, F.take(wilds, 5 - #flush_hand))
    end
    if #flush_hand >= 2 then
      local card_cnt = string.format(#flush_hand)
      table.insert(res, {
        hand = flush_hand,
        hand_type = card_cnt .. "flush"
      })
    end
  end
  return res
end

F.next_best_hand = function (possible_hands, curr_hand, hasher)
  if #possible_hands == 1 then return possible_hands[1].hand end
  if #possible_hands == 0 then return {} end
  if #curr_hand == 0 then return possible_hands[1].hand end

  -- if curr_hand is found in possible hands, select the next one
  -- otherwise, if only 1 card is selected, select best hand containing it
  -- otherwise, select best hand containing it (but is slower)
  local best_superset = false
  for i = 1, #possible_hands do
    if F.is_subset(curr_hand, possible_hands[i].hand, hasher) then
      if #curr_hand == #possible_hands[i].hand then
        if i == #possible_hands then
          return possible_hands[1].hand
        else
          return possible_hands[i + 1].hand
        end
      elseif #curr_hand == 1 then
        return possible_hands[i].hand
      else
        if not best_superset then
          best_superset = possible_hands[i].hand
        end
      end
    end
  end
  if best_superset then
    return best_superset
  end
  return possible_hands[1].hand
end

F.best_ofakinds = function (cards)
  local fives, fours, trips, twos = {}, {}, {}, {}
  local rank_counts = {}
  for i, card in pairs(cards) do
    local rank = F.get_visible_rank(card)
    if not (rank == "stone") then
      if not rank_counts[rank] then
        rank_counts[rank] = {}
      end
      table.insert(rank_counts[rank], card)
    end
  end
  for k, v in pairs(rank_counts) do
    table.sort(v, function(x, y) return F.calculate_importance(x, true) > F.calculate_importance(y, true) end)
    if #v >= 5 then
      table.insert(fives, F.take(v, 5))
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
  union = F.merge(union, fives)
  union = F.merge(union, fours)
  union = F.merge(union, trips)

  for i = 1, (#union - 1) do
    for j = i + 1, #union do
      table.insert(full_houses, F.merge(
        F.take(union[i], 3),
        F.take(union[j], 2)
      ))
      table.insert(full_houses, F.merge(
        F.take(union[i], 2),
        F.take(union[j], 3)
      ))
    end
  end
  for i = 1, #union do
    for k, v in pairs(twos) do
      table.insert(full_houses, F.merge(v, F.take(union[i], 3)))
    end
  end
  for i = 1, (#twos - 1) do
    for j = i + 1, #twos do
      table.insert(two_pairs, F.merge(twos[i], twos[j]))
    end
  end
  local res = {}
  res = F.merge(res, F.hands_to_named(fives, "5oak"))
  res = F.merge(res, F.hands_to_named(fours, "4oak"))
  res = F.merge(res, F.hands_to_named(full_houses, "fullhouse"))
  res = F.merge(res, F.hands_to_named(trips, "3oak"))
  res = F.merge(res, F.hands_to_named(two_pairs, "2pair"))
  res = F.merge(res, F.hands_to_named(twos, "2oak"))
  return res
end

F.select_hand = function (cards)
  G.hand:unhighlight_all()
  for k, v in pairs(cards) do
    if F.indexOf(G.hand.highlighted, function(x) return x == v end) == -1 then
      G.hand:add_to_highlighted(v, true)
    end
  end
  if next(cards) then
    play_sound("cardSlide1")
  else
    play_sound("cancel")
  end
end

F.select_best_hand = function (cards, accepted_hands)
  local hands = {}
  if accepted_hands.accept_str then
    hands = F.merge(hands, F.possible_straights(cards))
  end
  if accepted_hands.accept_flush then
    hands = F.merge(hands, F.possible_flushes(cards))
  end
  if accepted_hands.accept_oak then
    hands = F.merge(hands, F.best_ofakinds(cards))
  end
  table.sort(hands, F.is_better_hand)
  F.select_hand(F.next_best_hand(hands, G.hand.highlighted, F.ranksuit))
end

F.invert_selection = function ()
  local unselected = F.filter(G.hand.cards, function(x)
    return -1 == F.indexOf(G.hand.highlighted, function(y) return y == x end)
  end)
  table.sort(unselected, function(x, y) return F.calculate_importance(x, false) < F.calculate_importance(y, false) end)
  F.select_hand(F.take(unselected, 5))
end

F.bind_new_key = function (key, button)
  local button_text = button.children[1].children[1]
  button_text.config.text_drawable = nil
  button_text.config.text = key
  button_text:update_text()
  button.config.ref_table.configs[button.config.ref_table.key] = key
end

F.handle_hotkeys = function (key, handle_ref)
  if G.CONTROLLER and G.CONTROLLER.text_input_hook then
    return handle_ref()
  end
  key = key:sub(1, 1):upper() .. key:sub(2)
  if is_catching_key then
    if key == "Mouse1" or key == "Escape" then
    else
      F.bind_new_key(key, is_catching_key)
    end
    is_catching_key.config.colour = G.C.MULT
    is_catching_key.children[1].children[1].UIBox:recalculate()
    is_catching_key = false
    return
  end
  if G.STATE == G.STATES.SELECTING_HAND then
    local keycomp = function(x) return x == key end
    if key == config.best_hand_keys.key1 then
      F.select_best_hand(G.hand.cards, config.best_hand_keys.key1conf)
    elseif key == config.best_hand_keys.key2 then
      F.select_best_hand(G.hand.cards, config.best_hand_keys.key2conf)
    elseif not (F.indexOf(config.invert_keys, keycomp) == -1) then
      F.invert_selection()
    elseif not (F.indexOf(config.play_hand_keys, keycomp) == -1) then
      if #G.hand.highlighted > 0 and (not G.GAME.blind.block_play) and #G.hand.highlighted <= 5 then
        G.FUNCS.play_cards_from_highlighted()
      else
        play_sound("cancel")
      end
    elseif not (F.indexOf(config.discard_hand_keys, keycomp) == -1) then
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


F.wheelmovedref = love.wheelmoved or function() end
F.love_wheelmoved = function(x, y)
  local res_key = ""
  if y > 0 then
    res_key = "Scroll Up"
  else
    res_key = "Scroll Down"
  end
  F.handle_hotkeys(res_key, function() F.wheelmovedref(x, y) end)
end

F.mouseref = love.mousepressed
F.love_mousepressed = function(x, y, button, istouch, presses)
  local pressed_button = string.format("mouse%i", button)
  F.handle_hotkeys(pressed_button, function() F.mouseref(x, y, button, istouch, presses) end)
end

F.keyupdate_ref = Controller.key_press_update
F.Controller_key_press_update = function(self, key, dt)
  F.handle_hotkeys(key, function() F.keyupdate_ref(self, key, dt) end)
end


if
  -- backwards compat with previous versions, that will have this `== nil`
  config.apply_input_hooks ~= false
then
  love.wheelmoved = F.love_wheelmoved
  love.mousepressed = F.love_mousepressed
  Controller.key_press_update = F.Controller_key_press_update
end

print('Fishing Recipe Editor for GTPS Hosting | by VISGTPS')

local STORAGE_KEY = "visgtps_fishing_data"
local fullData = nil
local nonFishSessions = {}

local function getDefaultData()
    return {
        fish_recipes = {
            -- Wiggly Worm (2914)
            { bait_id = 2914, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 2914, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Shiny Flabby Thing (3012)
            { bait_id = 3012, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 3012, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Salmon Egg (3014)
            { bait_id = 3014, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 3014, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Risting Fly (3016)
            { bait_id = 3016, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 3016, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Shrimp Lure (3018)
            { bait_id = 3018, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 3018, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Whizmo Gizmo (3020)
            { bait_id = 3020, environment = "", fish_id = 3000, max_lbs = 15, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3026, max_lbs = 30, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3030, max_lbs = 50, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3038, max_lbs = 70, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3032, max_lbs = 90, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3034, max_lbs = 120, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3036, max_lbs = 160, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3814, max_lbs = 160, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 4958, max_lbs = 200, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 3024, max_lbs = 200, require_event = 0 },
            { bait_id = 3020, environment = "", fish_id = 7744, max_lbs = 200, require_event = 0 },
            -- Radioactive baits
            { bait_id = 5526, environment = "Radioactive", fish_id = 5538, max_lbs = 160, require_event = 0 },
            { bait_id = 5526, environment = "Radioactive", fish_id = 5580, max_lbs = 190, require_event = 0 },
            { bait_id = 5526, environment = "Radioactive", fish_id = 5542, max_lbs = 60, require_event = 0 },
            -- Ice baits
            { bait_id = 5528, environment = "Ice", fish_id = 5574, max_lbs = 190, require_event = 0 },
            { bait_id = 5528, environment = "Ice", fish_id = 5548, max_lbs = 60, require_event = 0 },
            { bait_id = 5528, environment = "Ice", fish_id = 5552, max_lbs = 120, require_event = 0 },
        },
        non_fish_recipes = {
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3022, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 444, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8966, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8964, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3810, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 1520, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 1522, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3448, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3028, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8256, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 846, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 1542, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3008, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 344, rod_id = 0 },
            { environment = "", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3184, rod_id = 0 },
            { environment = "", is_bonus = true, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8542, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8968, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5618, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5624, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5602, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5614, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5616, rod_id = 0 },
            { environment = "Ice", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8252, rod_id = 0 },
            { environment = "Radioactive", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 3584, rod_id = 0 },
            { environment = "Radioactive", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 8254, rod_id = 0 },
            { environment = "Radioactive", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5620, rod_id = 0 },
            { environment = "Radioactive", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5622, rod_id = 0 },
            { environment = "Radioactive", is_bonus = false, require_back_id = 0, require_event_id = 0, require_face_id = 0, require_feet_id = 0, require_hair_id = 0, require_hand_id = 0, require_mask_id = 0, require_necklace_id = 0, require_pants_id = 0, require_shirt_id = 0, require_world_kind = 0, result_count = 1, result_id = 5612, rod_id = 0 }
        }
    }
end

local function loadFullData()
    if fullData then return fullData end
    local saved = loadStringFromServer(STORAGE_KEY)
    if saved and saved ~= "" then
        local decoded = json.decode(saved)
        if decoded and type(decoded) == "table" then
            if decoded.fish_recipes and #decoded.fish_recipes > 0 then
                fullData = decoded
                return fullData
            end
        end
    end
    fullData = getDefaultData()
    saveFullData()
    return fullData
end

local function saveFullData()
    if not fullData then return end
    local newJson = json.encode(fullData)
    saveStringToServer(STORAGE_KEY, newJson)
end

local function itemName(id)
    local item = getItem(id)
    return item and item:getName() or tostring(id)
end

local function showMainMenu(player)
    local d = {}
    table.insert(d, "set_default_color|`w\n")
    table.insert(d, "set_bg_color|43,34,74,200|\n")
    table.insert(d, "set_border_color|112,86,191,255|\n")
    table.insert(d, "text_scaling_string|aaaaaaaaaaaaaaaa|\n")
    table.insert(d, "add_label_with_icon|big|`9Fishing `wMaster Editor|left|32|\n")
    table.insert(d, "add_spacer|small|\n")
    table.insert(d, "add_textbox|`oEdit all fishing recipes (fish and non-fish).|left|\n")
    table.insert(d, "add_spacer|small|\n")
    table.insert(d, "add_button_with_icon|fish_recipes|`wFish Recipes|staticBlueFrame|2914||left|width:0.4;text_scale:0.65;|\n")
    table.insert(d, "add_button_with_icon|non_fish_recipes|`wNon-Fish Recipes|staticBlueFrame|3022||left|width:0.4;text_scale:0.65;|\n")
    table.insert(d, "add_spacer|small|\n")
    table.insert(d, "add_quick_exit|\n")
    table.insert(d, "end_dialog|master_main|||\n")
    player:onDialogRequest(table.concat(d))
end

local function showFishBaitList(player)
    local data = loadFullData()
    if not data or not data.fish_recipes or #data.fish_recipes == 0 then
        player:onConsoleMessage("`4No fish recipes found! Please add some first.")
        return
    end
    
    local baitSet = {}
    for _, r in ipairs(data.fish_recipes) do
        if r.bait_id then
            baitSet[r.bait_id] = true
        end
    end
    
    local baitList = {}
    for id, _ in pairs(baitSet) do table.insert(baitList, id) end
    table.sort(baitList)

    if #baitList == 0 then
        player:onConsoleMessage("`4No bait found!")
        return
    end

    local d = {}
    table.insert(d, "set_default_color|`w\n")
    table.insert(d, "set_bg_color|43,34,74,200|\n")
    table.insert(d, "set_border_color|112,86,191,255|\n")
    table.insert(d, "text_scaling_string|aaaaaaaaaaaaaa

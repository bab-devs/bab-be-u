local scene = {}

world_parent = ""
world = ""

local title_font, label_font, icon_font, name_font
local ui, world_label
local text_input

local scrollx = 0
local scrolly = 0
local scrolloffset = 0
local scrollvel = 0

local full_height = 0

function scene.load()
  clear()
  resetMusic(current_music, 0.1)
  scene.buildUI()
  love.keyboard.setKeyRepeat(true)
  text_input = nil
end

function scene.update(dt)
  scrolloffset = scrolloffset + scrollvel * dt

  scrollvel = scrollvel - scrollvel * math.min(dt * 10, 1)
  if scrollvel < 0.1 and scrollvel > -0.1 then scrollvel = 0 end
  debugDisplay("scrollvel", scrollvel)
  debugDisplay("scrolloffset", scrolloffset)

  local scroll_height = math.max(0, full_height - love.graphics.getHeight())
  if scrolloffset > scroll_height then
    scrolloffset = scroll_height
    scrollvel = 0
  elseif scrolloffset < 0 then
    scrolloffset = 0
    scrollvel = 0
  end

  scrollx = scrollx+75*dt
  scrolly = scrolly+75*dt
end

function scene.keyPressed(key)
  if text_input then
    scene.updateTextInput(nil, key)
  else
    if key == "escape" then
      if world ~= "" then
        world_parent = ""
        world = ""
        scene.buildUI()
      else
        new_scene = menu
      end
    end
  end
end

function scene.textInput(text)
  scene.updateTextInput(text)
end

function scene.mouseReleased(x, y, mouse_button)
  if gooi.showingDialog then return end

  if mouse_button == 1 then
    for _,button in ipairs(ui.buttons) do
      if mouseOverBox(button.x, button.y, button.w, button.h, scene.getTransform()) then
        if button.type == "world" then
          world = button.name
          world_parent = button.data
          if button.create then
            love.filesystem.createDirectory(world_parent .. "/" .. world)
          end
          scene.buildUI()
          break
        elseif button.type == "level" then
          if button.create then
            loaded_level = false
            scene.loadLevel(button.data, true)
          else
            scene.loadLevel(button.data)
          end
        end
      end
    end
    if world_label and world_label.editable and mouseOverBox(world_label.x, world_label.y, world_label.w, world_label.h, scene.getTransform()) then
      if not text_input then
        text_input = {
          label = world_label,
          text = world_label.text,
          old_text = world_label.text,
          position = #world_label.text
        }
        love.keyboard.setTextInput(true)
      end
    end
  elseif mouse_button == 2 and world_parent ~= "officialworlds" then
    for _,button in ipairs(ui.buttons) do
      if mouseOverBox(button.x, button.y, button.w, button.h, scene.getTransform()) then
        if button.type == "world" then
          if not button.create then
            if not button.deletingconfirm then
              if not button.deleting then
			    playSound("move")
                button.deleting = true
              else
				playSound("unlock")
                button.deletingconfirm = true
              end
            else
              love.filesystem.remove(button.data .. "/" .. button.name)
              playSound("break")
              shakeScreen(0.3, 0.1)
              scene.buildUI()
            end
          end
        elseif button.type == "level" then
          if not button.create then
            if not button.deletingconfirm then
              if not button.deleting then
				playSound("move")
                button.deleting = true
              else
				playSound("unlock")
                button.deletingconfirm = true
			    end
            else
              if world == "" then
                love.filesystem.remove("levels/" .. button.name .. ".bab")
                love.filesystem.remove("levels/" .. button.name .. ".png")
                playSound("break")
                shakeScreen(5, 3)
              else
                love.filesystem.remove(world_parent .. "/" .. world .. "/" .. button.name .. ".bab")
                love.filesystem.remove(world_parent .. "/" .. world .. "/" .. button.name .. ".png")
                playSound("break")
                shakeScreen(5, 3)
              end
              scene.buildUI()
            end
          end
        end
      end
    end
  end
end

function scene.wheelMoved(whx, why) -- The wheel moved, Why?
  scrollvel = scrollvel + (-191 * why * 3)
  -- why = "well i dont fuckin know the person who moved it probably wanted it to move"
end

function scene.getTransform()
  local transform = love.math.newTransform()

  transform:translate(0, -scrolloffset)

  return transform
end

function scene.draw()
  love.graphics.clear(0.10, 0.1, 0.11, 1)

  local bgsprite = sprites["ui/menu_background"]

  local cells_x = math.ceil(love.graphics.getWidth() / bgsprite:getWidth())
  local cells_y = math.ceil(love.graphics.getHeight() / bgsprite:getHeight())

  love.graphics.setColor(1, 1, 1, 0.6)
  setRainbowModeColor(love.timer.getTime()/6, .4)
  
  for x = -1, cells_x do
    for y = -1, cells_y do
      local draw_x = scrollx % bgsprite:getWidth() + x * bgsprite:getWidth()
      local draw_y = scrolly % bgsprite:getHeight() + y * bgsprite:getHeight()
      love.graphics.draw(bgsprite, draw_x, draw_y)
    end
  end

  -- ui
  love.graphics.push()
  love.graphics.applyTransform(scene.getTransform())
  love.graphics.setColor(1, 1, 1, 1)

  for i,button in ipairs(ui.buttons) do
    local sprite_name = "ui/" .. button.type .. " box"
    if button.deletingconfirm then
      sprite_name = sprite_name .. " deleteconfirm"
    elseif button.deleting then
      sprite_name = sprite_name .. " delete"
    end
    local sprite = sprites[sprite_name]
    local btncolor = {1, 1, 1}

    local sx, sy

    if button.icon then
      local imgw, imgh = button.icon:getWidth(), button.icon:getHeight()
      --scale factors
      sx, sy = ICON_WIDTH / imgw, ICON_HEIGHT / imgh
    end

    love.graphics.push()
    if mouseOverBox(button.x, button.y, button.w, button.h, scene.getTransform()) then
      love.graphics.translate(button.x+button.w/2, button.y+button.h/2)
      love.graphics.scale(1.1)
      love.graphics.rotate(0.05 * math.sin(love.timer.getTime()*5))
      love.graphics.translate(-button.x-button.w/2, -button.y-button.h/2)
    else
      button.deleting = false
	  button.deletingconfirm = false
    end

    if rainbowmode then btncolor = hslToRgb((love.timer.getTime()/6+i*10)%1, .5, .5, .9) end
    love.graphics.setColor(btncolor)

    if button.type == "world" then
      love.graphics.draw(sprite, button.x, button.y)
      love.graphics.setColor(1, 1, 1)
      if button.icon then
        love.graphics.draw(button.icon,
          button.x + (button.w / 2) - (ICON_WIDTH / 2),
          button.y + (button.h / 2) - (ICON_HEIGHT / 2))
      else
        love.graphics.setFont(icon_font)

        local _,lines = icon_font:getWrap(button.name:upper(), 96)
        local height = #lines * icon_font:getHeight()

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.name:upper(), button.x + (button.w / 2) - (96 / 2), button.y + (button.h / 2) - (height / 2), 96, "center")
      end
    elseif button.type == "level" then
      local icon_y_multiplier = 2/3
      if button.create then icon_y_multiplier = 1/2 end

      if button.data.extra then
        love.graphics.setColor(btncolor[1]-0.4, btncolor[2]-0.4, btncolor[3]-0.4)
      end
      love.graphics.draw(sprite, button.x, button.y)

      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(button.icon,
        button.x + (button.w / 2) - (ICON_WIDTH / 2),
        button.y + (button.h * icon_y_multiplier) - (ICON_HEIGHT / 2),
        0, sx, sy)
      
      if not button.create then
        love.graphics.setFont(name_font)

        local _,lines = name_font:getWrap(button.data.name:upper(), 112)
        local height = #lines * name_font:getHeight()

        local btnprintname
        if button.data.extra then
          btnprintname = button.data.name:lower()
        else
          btnprintname = button.data.name:upper()
        end

        love.graphics.printf(btnprintname, button.x + (button.w / 2) - (112 / 2), button.y + 40 - (height / 2), 112, "center")
      end
    end
    love.graphics.pop()
  end

  for _,label in ipairs(ui.labels) do
    love.graphics.setFont(label.font)
    local text_width = label.font:getWidth(label.text)
    local font_height = label.font:getHeight()
    if label.editable and mouseOverBox(label.x, label.y, label.w or love.graphics.getWidth(), label.h or font_height) then
      love.graphics.setColor(0.75, 0.75, 0.75, 1)
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf(label.text, label.x, label.y, label.w or love.graphics.getWidth(), label.align or "center")

    if text_input and text_input.label == label then
      love.graphics.setLineWidth(1)
      local x = label.x + label.w / 2 - text_width / 2 + label.font:getWidth(label.text:sub(1, text_input.position))
      if math.floor(love.timer.getTime()*2) % 2 == 0 then
        love.graphics.line(x, label.y, x, label.y + font_height)
      end
    end
  end

  love.graphics.pop()
  gooi.draw()
end

function scene.loadLevel(data, new)
  local loaddata = love.data.decode("string", "base64", data.map)
  local mapstr = love.data.decompress("string", "zlib", loaddata)

  loaded_level = not new

  level_name = data.name
  level_author = data.author or ""
  current_palette = data.palette or "default"
  map_music = data.music or "bab be u them"
  mapwidth = data.width
  mapheight = data.height
  map_ver = data.version or 0

  if map_ver == 0 then
    map = loadstring("return " .. mapstr)()
  else
    map = mapstr
  end

  if load_mode == "edit" then
    new_scene = editor
  elseif load_mode == "play" then
    new_scene = game
  end

  local dir = "levels/"
  if world ~= "" then dir = world_parent .. "/" .. world .. "/" end
  if love.filesystem.getInfo(dir .. level_name .. ".png") then
    icon_data = love.image.newImageData(dir .. level_name .. ".png")
  else
    icon_data = nil
  end
end

function scene.buildUI()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  title_font = love.graphics.newFont(32)
  label_font = love.graphics.newFont(24)
  icon_font = love.graphics.newFont(16)
  name_font = love.graphics.newFont(12)
  icon_font:setFilter("nearest","nearest")
  name_font:setFilter("nearest","nearest")

  ui = {}
  ui.labels = {}
  ui.buttons = {}

  local oy = 4
  if world ~= "" then
    local title_width, title_height = title_font:getWidth(world:upper()), title_font:getHeight()
    world_label = {
      font = title_font,
      text = world:upper(),
      x = 0,
      y = oy,
      w = love.graphics.getWidth(),
      h = title_height
    }
    if load_mode == "edit" and world_parent ~= "officialworlds" and world ~= "" then
      world_label.editable = true
    end
    table.insert(ui.labels, world_label)
    oy = oy + title_height + 24
  end

  if world == "" then
    local worlds = scene.searchDir("officialworlds", "world")
    if #worlds > 0 then
      local label_width, label_height = label_font:getWidth("Official Worlds"), label_font:getHeight()
      table.insert(ui.labels, {
        font = label_font,
        text = "Official Worlds",
        x = 0,
        y = oy
      })
      oy = oy + label_height + 8

      oy = scene.addButtons("world", worlds, oy)
    end

    worlds = scene.searchDir("worlds", "world")
    if #worlds > 0 or load_mode == "edit" then
      label_width, label_height = label_font:getWidth("Custom Worlds"), label_font:getHeight()
      table.insert(ui.labels, {
        font = label_font,
        text = "Custom Worlds",
        x = 0,
        y = oy
      })
      oy = oy + label_height + 8

      if load_mode == "edit" and world_parent ~= "officialworlds" then
        table.insert(worlds, 1, {
          create = true,
          name = "new world",
          data = "worlds",
          icon = sprites["ui/create icon"]
        })
      end

      oy = scene.addButtons("world", worlds, oy)
    end

    local levels = scene.searchDir("levels", "level")
    if #levels > 0 or load_mode == "edit" then
      label_width, label_height = label_font:getWidth("Custom Levels"), label_font:getHeight()
      table.insert(ui.labels, {
        font = label_font,
        text = "Custom Levels",
        x = 0,
        y = oy
      })
      oy = oy + label_height + 8

      if load_mode == "edit" and world_parent ~= "officialworlds" then
        table.insert(levels, 1, {
          create = true,
          name = "new level",
          data = json.decode(default_map),
          icon = sprites["ui/create icon"]
        })
      end

      oy = scene.addButtons("level", levels, oy)
    end
  else
    local levels = scene.searchDir(world_parent .. "/" .. world, "level")
    if #levels > 0 or load_mode == "edit" then
      label_width, label_height = label_font:getWidth("Levels"), label_font:getHeight()
      table.insert(ui.labels, {
        font = label_font,
        text = "Levels",
        x = 0,
        y = oy
      })
      oy = oy + label_height + 8

      if load_mode == "edit" and world_parent ~= "officialworlds" then
        table.insert(levels, 1, {
          create = true,
          name = "new level",
          data = json.decode(default_map),
          icon = sprites["ui/create icon"]
        })
      end

      oy = scene.addButtons("level", levels, oy)
    end
  end

  full_height = oy + 8
end

function scene.searchDir(dir, type)
  local ret = {}
  local dirs = love.filesystem.getDirectoryItems(dir)

  local filtered = filter(dirs, function(file)
    if type == "world" then
      return love.filesystem.getInfo(dir .. "/" .. file).type == "directory"
    elseif type == "level" then
      return file:ends(".bab")
    end
  end)

  table.sort(filtered, function(a, b)
    local a_, b_ = a, b
    if type == "level" then
      a_ = a:sub(1, -5)
      b_ = b:sub(1, -5)
    end
    return a_ < b_
  end)

  for _,file in ipairs(filtered) do
    local t = {}
    if type == "world" then
      t.name = file
      t.data = dir
      if love.filesystem.getInfo(dir .. "/" .. file .. "/icon.png") then
        t.icon = love.graphics.newImage(dir .. "/" .. file .. "/icon.png")
      end
    elseif type == "level" then
      t.name = file:sub(1, -5)
      t.data = json.decode(love.filesystem.read(dir .. "/" .. file))
      if love.filesystem.getInfo(dir .. "/" .. t.name .. ".png") then
        t.icon = love.graphics.newImage(dir .. "/" .. t.name .. ".png")
      else
        t.icon = sprites["ui/default icon"]
      end
    end
    table.insert(ret, t)
  end
  return ret
end

function scene.addButtons(type, list, oy)
  local sw = love.graphics.getWidth()
  local btn_width, btn_height
  if type == "world" then
    btn_width, btn_height = sprites["ui/world box"]:getWidth(), sprites["ui/world box"]:getHeight()
  elseif type == "level" then
    btn_width, btn_height = sprites["ui/level box"]:getWidth(), sprites["ui/level box"]:getHeight()
  end
  local final_list = {}
  for i,v in ipairs(list) do
    local row = math.floor((i - 1) / math.floor(sw / (btn_width + 8))) + 1
    if not final_list[row] then
      final_list[row] = {}
    end
    table.insert(final_list[row], v)
  end
  for row,cols in ipairs(final_list) do
    local width = (btn_width * #cols) + ((#cols - 1) * 8)
    local ox = (sw / 2) - (width / 2)
    for col,v in ipairs(cols) do
      local button = {
        type = type,
        name = v.name,
        x = ox,
        y = oy,
        w = btn_width,
        h = btn_height,
        icon = v.icon,
        data = v.data,
        create = v.create,
      }
      table.insert(ui.buttons, button)

      ox = ox + btn_width + 8
    end
    oy = oy + btn_height + 8
  end
  return oy
end

function scene.resize(w, h)
  scene.buildUI()
end

function scene.updateTextInput(text, key)
  if text_input then
    if not text then
      if key == "return" then
        text_input.label.text = text_input.text:upper()
        -- hardcoding for now
        renameDir(world_parent .. "/" .. world, world_parent .. "/" .. text_input.text:lower())
        world = text_input.text:lower()
        scene.buildUI()
        text_input = nil
      elseif key == "escape" then
        text_input.label.text = text_input.old_text
        text_input = nil
        love.keyboard.setTextInput(false)
      elseif key == "backspace" then
        local a = text_input.text:sub(1, math.max(0, text_input.position - 1))
        local b = text_input.text:sub(text_input.position + 1)
        text_input.text = a .. b
        text_input.position = math.max(0, text_input.position - 1)
      elseif key == "left" then
        text_input.position = math.max(0, text_input.position - 1)
      elseif key == "right" then
        text_input.position = math.min(#text_input.text, text_input.position + 1)
      end
    else
      local a = text_input.text:sub(1, text_input.position)
      local b = text_input.text:sub(text_input.position + 1)
      text_input.text = a .. text .. b
      text_input.position = text_input.position + 1
    end
    if text_input then
      text_input.label.text = text_input.text:upper()
    end
  end
end

return scene
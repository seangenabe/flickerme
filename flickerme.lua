include("karaskel.lua")

script_name = "flickerme"
script_description = "Add flicker effects to individual characters"
script_version = "1"

FLICKER_DURATION = 200
FLICKER_STEP = 50

function fx_flicker(subs, meta, styles, ell, fxdata)
  local line = table.copy(ell)
  local tokensIterator = string.gmatch(fxdata, "%S+")
  local tokens = {}
  for token in tokensIterator do
    tokens[token] = true
  end

  local function align_line(tokens, line)
    -- Alignment
    if tokens.alignleft then
      line.text = "{\\an1}" .. line.text
    elseif tokens.alignright then
      line.text = "{\\an3}" .. line.text
    end
    if string.match(line.style, "Outline") then
      line.text = "{\\blur1\\be1}" .. line.text
    end
    line.effect = "fx"
    line.comment = false
    return line
  end

  -- Collect characters
  local _chars = string.gmatch(line.text, ".")
  local chars = {}
  for char in _chars do
    table.insert(chars, char)
  end

  -- Generate start animation
  if tokens.both then
    tokens.cstart = true
    tokens.cend = true
  end
  for _, loc in ipairs({"cstart", "cend"}) do
    if tokens[loc] then
      for offset = 0, FLICKER_DURATION - FLICKER_STEP, FLICKER_STEP do
        local new_line = table.copy(line)
        local new_chars = ""
        for _, char in ipairs(chars) do
          local new_char = "{\\r\\blur1}"
          local alpha = math.random(4)
          if alpha == 1 then
            new_char = new_char .. "{\\alpha&HFF&}"
          elseif alpha == 2 then
            new_char = new_char .. "{\\alpha&HA0&}"
          elseif alpha == 3 then
            new_char = new_char .. "{\\alpha&HC0&}"
          end
          new_char = new_char .. char
          new_chars = new_chars .. new_char
        end
        new_line.text = new_chars

        -- Retime line
        if loc == "cstart" then
          new_line.start_time = line.start_time + offset
          new_line.end_time = line.start_time + offset + FLICKER_STEP
        elseif loc == "cend" then
          new_line.start_time = line.end_time - offset - FLICKER_STEP
          new_line.end_time = line.end_time - offset
        end

        new_line = align_line(tokens, new_line)
        subs.append(new_line)
      end
    end
  end

  -- Re-add original line
  if tokens.cstart then
    line.start_time = line.start_time + FLICKER_DURATION + FLICKER_STEP
  end
  if tokens.cend then
    line.end_time = line.end_time - FLICKER_DURATION - FLICKER_STEP
  end

  line = align_line(tokens, line)
  subs.append(line)

  return false
end

karaskel.use_fx_library_furi(false, true)

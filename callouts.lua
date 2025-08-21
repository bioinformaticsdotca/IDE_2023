-- callouts_conditional.lua
-- Handles static, regular/important/subtle dropdowns, and plain dropdowns.

local function get_default_icon(type)
  if type == "red" then return "fas fa-triangle-exclamation"
  elseif type == "blue" then return "fas fa-circle-info"
  elseif type == "green" then return "fas fa-circle-check"
  elseif type == "yellow" then return "fas fa-bell"
  elseif type == "purple" then return "fas fa-star"
  elseif type == "orange" then return "fas fa-fire"
  elseif type == "gray" then return "fas fa-comment-dots"
  else return "fas fa-info-circle"
  end
end

local function create_icon_element(icon_attr, type)
  local show_icon = true
  if icon_attr == "false" then show_icon = false end

  if show_icon then
    local icon_fa_class = (icon_attr and icon_attr ~= "true") and icon_attr or get_default_icon(type)
    local i_tag = pandoc.RawInline('html', '<i class="' .. icon_fa_class .. '" aria-hidden="true"></i>')
    return pandoc.Span({i_tag}, {class = "callout-icon"})
  end
  return nil
end

local function create_title_element(title_text, center_title_attr, is_summary_title, summary_title_class, static_title_class_arg)
  if title_text and title_text ~= "" then
    local title_inline_content
    local parsed_title_blocks = pandoc.read(title_text, 'markdown').blocks
    if parsed_title_blocks and #parsed_title_blocks > 0 and parsed_title_blocks[1].t == "Para" then
        title_inline_content = parsed_title_blocks[1].content
    else
        title_inline_content = {pandoc.Str(title_text)}
    end

    if is_summary_title then
        return pandoc.Span(title_inline_content, {class = summary_title_class or "callout-dropdown-title"})
    else
        local title_block_content = pandoc.Para(title_inline_content)
        local current_static_title_class = static_title_class_arg or "callout-title-static"
        local title_classes_list = {current_static_title_class}
        if center_title_attr == "true" then table.insert(title_classes_list, "center") end
        local kv_attributes_list = { {"style", "margin-bottom: 0.5em;"} }
        local final_attrs = pandoc.Attr("", title_classes_list, kv_attributes_list)
        return pandoc.Div({title_block_content}, final_attrs)
    end
  end
  return nil
end

function Div(el)
  if el.classes:includes("callout") then
    local type = el.attributes.type
    local style = el.attributes.style or "regular"
    local title_text = el.attributes.title
    local icon_attr = el.attributes.icon
    local center_title = el.attributes.center_title
    local is_collapsible = el.attributes.collapsible == "true"

    if not type or type == "" then
      io.stderr:write("Callout Warning: 'type' attribute is missing or empty for a .callout div.\n")
      return el
    end

    local icon_element = create_icon_element(icon_attr, type)

    if is_collapsible then
      local details_classes = {"callout-dropdown"}
      local base_type_class = "callout-" .. type -- e.g. callout-red, for icon color on plain style

      if style == "plain" then
        table.insert(details_classes, "callout-plain")
        table.insert(details_classes, base_type_class) -- Add type class for potential icon coloring
      elseif style == "subtle" then
        table.insert(details_classes, "callout-subtle")
        table.insert(details_classes, base_type_class .. "-subtle")
      else -- regular or important
        table.insert(details_classes, base_type_class .. (style == "important" and "-important" or ""))
      end

      local summary_classes = {"callout-dropdown-summary"}
      if icon_element and style == "plain" then -- Add helper class if icon present in plain summary
        table.insert(summary_classes, "summary-has-icon")
      end

      local summary_children = {}
      if icon_element then table.insert(summary_children, icon_element) end

      local summary_title_text_val = title_text or "Details"
      local summary_title_element = create_title_element(summary_title_text_val, nil, true, "callout-dropdown-title", nil)
      if summary_title_element then table.insert(summary_children, summary_title_element) end

      local caret_i_tag = pandoc.RawInline('html', '<i class="fas fa-chevron-right" aria-hidden="true"></i>')
      local caret_span_element = pandoc.Span({caret_i_tag}, {class = "callout-dropdown-caret"})
      table.insert(summary_children, caret_span_element)

      local plain_block_for_summary = pandoc.Plain(summary_children)
      local temp_doc_for_summary = pandoc.Pandoc({plain_block_for_summary})
      local summary_html_content = pandoc.write(temp_doc_for_summary, 'html')
      summary_html_content = summary_html_content:gsub("^<p>", ""):gsub("</p>\n?$", "")

      local summary_element_html = '<summary class="'.. table.concat(summary_classes, " ") ..'">' .. summary_html_content .. '</summary>'
      local content_div_element = pandoc.Div(el.content, {class = "callout-dropdown-content"})
      local details_open_tag = '<details class="' .. table.concat(details_classes, " ") .. '">'
      local details_close_tag = '</details>'

      return {
          pandoc.RawBlock('html', details_open_tag),
          pandoc.RawBlock('html', summary_element_html),
          content_div_element,
          pandoc.RawBlock('html', details_close_tag)
      }
    else -- Static callout
      local specific_style_class = "callout-" .. type
      if style == "important" then specific_style_class = specific_style_class .. "-important"
      elseif style == "subtle" then specific_style_class = specific_style_class .. "-subtle"
      end
      -- Note: style="plain" for static callouts is not specifically handled here to remove borders/bg,
      -- users would need a .callout-plain static CSS if desired. Focus is on plain dropdown.

      local title_element = create_title_element(title_text, center_title, false, nil, "callout-title-static")
      local content_div_inner_blocks = {}
      if title_element then table.insert(content_div_inner_blocks, title_element) end
      for _, block in ipairs(el.content) do table.insert(content_div_inner_blocks, block) end
      local content_div_element = pandoc.Div(content_div_inner_blocks, {class = "callout-content"})

      local main_div_children = {}
      if icon_element then table.insert(main_div_children, icon_element) end
      table.insert(main_div_children, content_div_element)

      return pandoc.Div(main_div_children, {class = specific_style_class})
    end
  end
  return nil
end

return {{Div = Div}}

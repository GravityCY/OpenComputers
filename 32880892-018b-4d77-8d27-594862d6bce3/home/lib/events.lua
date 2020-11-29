--  The Event object.
Event = {
    events   = {},
    silenced = {}
  }
  
  -- Create an event.
  function Event.create(event)
    if not Event.events[event] then
      Event.events[event] = {}
    end
  end
  
  -- Remove an event.
  function Event.remove(event)
    Event.events[event] = nil
  end
  
  -- Check to see if an event is known.
  function Event.has_event(event)
    return Event.events[event] == nil -- will be nil if it doesn't exist.
  end
  
  function Event.observe(event, callback, do_create)
    if not Event.has_event(event) and do_create then
      Event.create(event)
    else
      return nil
    end
  
    table.insert(Event.events[event], callback)
  
    return callback
  end
  
  function Event.unobserve(event, callback)
    if Event.has_event(event) then
      local tmp = {}
  
      for _, cb in Event.events[event] do
        if not callback == cb then
          table.insert(tmp, cb)
        end
      end
  
      Event.events[event] = tmp
      return true
    end
  
    return false
  end
  

  function Event.emit(event, args)
    if Event.has_event(event) then
  
      if not args then args = {} end
  
      local ev = {type = event, args = args}
  
      for _, callback in ipairs(Event.events[event]) do
        callback(event, ev)
      end
    end
  end

  function Event.silence(event, ...)
    if not Event.silenced[event] then
      Event.silenced[event] = true
    end
  
    if type(arg[1]) == "function" then
      local callback = table.remove(arg, 1)
  
      callback(table.unpack(arg))
      Event.silenced[event] = nil
    end
    
    return Event.silenced[event]
  end
  
  -- Remove the silencing of an event.
  function Event.unsilence(event)
    Event.silenced[event] = nil
  end
  
  -- Checks to see if an event is silenced.
  function Event.is_silenced(event)
    return Event.silenced[event]
  end
  
  
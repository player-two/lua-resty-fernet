local cjson = require "cjson"
local fernet = require "resty.fernet"


local function readfile(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end


local function parse_time(ts)
  local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)([+-])(%d+):(%d+)"
  local year, month, day, hour, min, sec, tz_dir, tz_hours, _ = string.match(ts, pattern)
  local now = os.time({ year=year, month=month, day=day, hour=hour, min=min, sec=sec })
  if tz_dir == "+" then
    tz_hours = 0 - tz_hours
  end
  return now + 3600 * tz_hours
end


local total = 0
local failing = 0


local function pass(msg)
  total = total + 1
  print("\27[32m" .. msg .. "\27[39m")
end


local function fail(msg)
  total = total + 1
  failing = failing + 1
  print("\27[31m" .. msg .. "\27[39m")
end


local function review(msg)
  total = total + 1
  print("\27[33m" .. msg .. "\27[39m")
end


local function test_generate(case)
  local f = fernet:new(case.secret)
  local iv = ""
  for _, b in ipairs(case.iv) do
    iv = iv .. string.char(b)
  end
  f._time = function(self) return parse_time(case.now) end
  f._iv = function(self) return iv end

  local token, err = f:encrypt(case.src)
  if err then
    return err
  end
  if token ~= case.token then
    return "expected " .. case.token .. ", got " .. token
  end

  return nil
end


local function test_verify(case)
  local f = fernet:new(case.secret)
  f._time = function(self) return parse_time(case.now) end

  local src, err = f:decrypt(case.token, case.ttl_sec)
  if err then return err end
  if case.src and src ~= case.src then
    return "expected " .. case.src .. ", got " .. src
  end

  return nil
end


local generate = cjson.decode(assert(readfile("spec/generate.json")))
for _, case in pairs(generate) do
  local err = test_generate(case)
  if err then
    fail("generate test failed: " .. err)
  else
    pass("generate test passed")
  end
end


local verify = cjson.decode(assert(readfile("spec/verify.json")))
for _, case in pairs(verify) do
  local err = test_verify(case)
  if err then
    fail("verify test failed: " .. err)
  else
    pass("verify test passed")
  end
end


local invalid = cjson.decode(assert(readfile("spec/invalid.json")))
for _, case in pairs(invalid) do
  print("negative test '" .. case.desc .. "':")
  local ok, value = pcall(function () return test_verify(case) end)
  if ok then
    if value then
      review("  review expected error '" .. value .. "'")
    else
      fail("  should have returned an error, but did not")
    end
  else
    fail("  failed with uncaught error: " .. value)
  end
end


print(string.format("%d test ran - %d failures", total, failing))
